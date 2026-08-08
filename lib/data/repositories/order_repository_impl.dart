import 'package:drift/drift.dart';

import '../../core/entities/coupon.dart';
import '../../core/entities/order.dart';
import '../../core/entities/order_status.dart';
import '../../core/entities/shipping_info.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/order_repository.dart';
import '../database/app_database.dart';
import '../database/daos/cart_dao.dart';
import '../database/daos/coupon_dao.dart';
import '../database/daos/order_dao.dart';
import '../database/daos/product_dao.dart';
import '../database/mappers/coupon_mapper.dart';
import '../database/mappers/order_mapper.dart';
import '../database/mappers/product_mapper.dart';
import '../guarded_result.dart';

/// drift-backed [OrderRepository].
///
/// The error boundary (Section D.4): every one-shot operation wraps drift
/// exceptions in [Result] here. `placeOrder` orchestrates several aggregates
/// (cart, products, orders), so it composes their DAOs and runs all writes in
/// a single [AppDatabase.transaction] — the atomicity guarantee of the plan.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(
    this._orderDao,
    this._productDao,
    this._cartDao,
    this._couponDao,
    this._productMapper,
    this._orderMapper,
    this._couponMapper,
    this._db,
  );

  final OrderDao _orderDao;
  final ProductDao _productDao;
  final CartDao _cartDao;
  final CouponDao _couponDao;
  final ProductMapper _productMapper;
  final OrderMapper _orderMapper;
  final CouponMapper _couponMapper;
  final AppDatabase _db;

  @override
  Stream<List<Order>> watchOrders() => _orderDao.watchAll().asyncMap(
        (rows) async => [
          for (final row in rows) await _loadAggregate(row.id, row),
        ],
      );

  @override
  Stream<Order?> watchOrderById(int id) => _orderDao.watchById(id).asyncMap(
        (row) async => row == null ? null : await _loadAggregate(row.id, row),
      );

  @override
  Future<Result<Order>> getById(int id) => guardedLoadById(
        () => _orderDao.getById(id),
        message: 'Could not load order',
        notFoundCode: AppErrorCode.orderNotFound,
        notFoundMessage: 'Order not found',
        map: (row) => _loadAggregate(row.id, row),
      );

  @override
  Future<Result<Order>> placeOrder(
    ShippingInfo shipping, {
    String? couponCode,
  }) =>
      guardedResult(() async {
        final cartRows = await _cartDao.getAll();
        if (cartRows.isEmpty) {
          return const Failure(ValidationError(
            code: AppErrorCode.cartEmpty,
            message: 'Cart is empty',
          ));
        }

        // Validate everything BEFORE the transaction: read current products
        // and compute the snapshot totals with the domain's integer money
        // math. Nothing is written until every line is provably placeable.
        final lines = <({
          int productId,
          String name,
          String? nameAr,
          int priceCents,
          int discountPercent,
          int quantity,
          int stock,
        })>[];
        var subtotalCents = 0;
        var discountCents = 0;
        for (final cart in cartRows) {
          final productRow = await _productDao.getById(cart.productId);
          if (productRow == null) {
            return const Failure(NotFoundError(
              code: AppErrorCode.cartProductUnavailable,
              message: 'A product in your cart is no longer available',
            ));
          }
          if (productRow.stock < cart.quantity) {
            return Failure(StockLimitError(
              productName: productRow.name,
              stock: productRow.stock,
              currentInCart: cart.quantity,
              message: 'Not enough stock for ${productRow.name}',
            ));
          }
          final product = _productMapper.toEntity(productRow);
          subtotalCents += product.priceCents * cart.quantity;
          discountCents += product.savingsCents * cart.quantity;
          lines.add((
            productId: product.id,
            name: product.name,
            nameAr: product.nameAr,
            priceCents: product.priceCents,
            discountPercent: product.discountPercent,
            quantity: cart.quantity,
            stock: product.stock,
          ));
        }
        // Coupon: re-validated here (authoritative — the checkout preview is
        // advisory). Uses the line-discounted subtotal as the eligible spend,
        // then adds its discount on top of the line savings.
        final now = DateTime.now();
        var couponDiscountCents = 0;
        String? appliedCouponCode;
        int? appliedCouponId;
        final normalizedCode =
            couponCode == null ? '' : normalizeCouponCode(couponCode);
        if (normalizedCode.isNotEmpty) {
          final couponRow = await _couponDao.getByCode(normalizedCode);
          if (couponRow == null) {
            return Failure(CouponNotFoundError(
              couponCode: normalizedCode,
              message: 'No coupon with code $normalizedCode',
            ));
          }
          final coupon = _couponMapper.toEntity(couponRow);
          final check = coupon.applyTo(
            subtotalCents - discountCents,
            now: now,
          );
          switch (check) {
            case CouponValid(:final discountCents):
              couponDiscountCents = discountCents;
              appliedCouponCode = normalizedCode;
              appliedCouponId = coupon.id;
            case CouponInvalid(:final error):
              return Failure(error);
          }
        }
        final totalDiscountCents = discountCents + couponDiscountCents;
        final totalCents = subtotalCents - totalDiscountCents;

        final order = await _db.transaction(() async {
          // Sequential order numbers (ORD-00000N) minted from the highest row
          // id so they never collide with the seed's ORD-000001..6.
          final nextNumber = (await _orderDao.maxOrderId() ?? 0) + 1;
          final orderId = await _orderDao.insertOrder(OrdersCompanion.insert(
            orderNumber: 'ORD-${nextNumber.toString().padLeft(6, '0')}',
            status: OrderStatus.pending,
            subtotalCents: subtotalCents,
            discountCents: totalDiscountCents,
            couponCode: Value(appliedCouponCode),
            couponDiscountCents: Value(couponDiscountCents),
            totalCents: totalCents,
            shippingName: shipping.name,
            shippingPhone: shipping.phone,
            shippingAddress: shipping.address,
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ));
          // Coupon usage is booked in the same transaction as the order, so a
          // use and its order can never drift apart (rolled back together).
          if (appliedCouponId != null) {
            await _couponDao.incrementUsedCount(appliedCouponId);
          }
          for (final line in lines) {
            await _orderDao.insertOrderItem(OrderItemsCompanion.insert(
              orderId: orderId,
              // productId is nullable -> Value<T?> (no ternary needed).
              productId: Value(line.productId),
              productName: line.name,
              productNameAr: Value(line.nameAr),
              unitPriceCents: line.priceCents,
              discountPercent: Value(line.discountPercent),
              quantity: line.quantity,
            ));
            // Stock decrement: explicit value (we already validated against
            // it and hold the pre-order stock in the line record).
            await _productDao.updateById(
              line.productId,
              ProductsCompanion(
                stock: Value(line.stock - line.quantity),
                updatedAt: Value(now.millisecondsSinceEpoch),
              ),
            );
          }
          await _orderDao.insertHistoryEntry(OrderStatusHistoryCompanion.insert(
            orderId: orderId,
            status: OrderStatus.pending,
            changedAt: now.millisecondsSinceEpoch,
          ));
          await _cartDao.deleteAll();
          final row = (await _orderDao.getById(orderId))!;
          return _loadAggregate(row.id, row);
        });
        return Success(order);
      }, message: 'Could not place order');

  @override
  Future<Result<Order>> updateStatus(
    int orderId,
    OrderStatus newStatus,
  ) =>
      guardedResult(() async {
        final row = await _orderDao.getById(orderId);
        if (row == null) {
          return const Failure(NotFoundError(
            code: AppErrorCode.orderNotFound,
            message: 'Order not found',
          ));
        }
        if (!row.status.canTransitionTo(newStatus)) {
          return Failure(ValidationError(
            code: AppErrorCode.invalidStatusTransition,
            message:
                'Cannot move order from ${row.status.label} to ${newStatus.label}',
          ));
        }

        final now = DateTime.now();
        await _db.transaction(() async {
          await _orderDao.updateStatusById(
            orderId,
            newStatus,
            now.millisecondsSinceEpoch,
          );
          await _orderDao.insertHistoryEntry(OrderStatusHistoryCompanion.insert(
            orderId: orderId,
            status: newStatus,
            changedAt: now.millisecondsSinceEpoch,
          ));
        });
        // Re-read through the aggregate path so the returned Order reflects
        // the new status and history.
        return getById(orderId);
      }, message: 'Could not update order status');

  /// Assembles the aggregate from the order row plus its lines and history.
  Future<Order> _loadAggregate(int id, OrderRow row) async {
    final items = await _orderDao.getItemsForOrder(id);
    final history = await _orderDao.getHistoryForOrder(id);
    return _orderMapper.toEntity(order: row, items: items, history: history);
  }
}

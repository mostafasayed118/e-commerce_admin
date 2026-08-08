import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/cart_dao.dart';
import 'package:shop_admin/data/database/daos/coupon_dao.dart';
import 'package:shop_admin/data/database/daos/order_dao.dart';
import 'package:shop_admin/data/database/daos/product_dao.dart';
import 'package:shop_admin/data/database/mappers/coupon_mapper.dart';
import 'package:shop_admin/data/database/mappers/order_mapper.dart';
import 'package:shop_admin/data/database/mappers/product_mapper.dart';
import 'package:shop_admin/data/repositories/cart_repository_impl.dart';
import 'package:shop_admin/data/repositories/order_repository_impl.dart';
import 'package:shop_admin/domain/repositories/order_repository.dart';

/// ProductDao whose [ProductDao.updateById] always throws — used to prove
/// that placeOrder rolls back a partially-written transaction. Reads are
/// untouched, so validation succeeds and the failure happens mid-write.
class _ExplodingProductDao extends ProductDao {
  _ExplodingProductDao(super.attachedDatabase);

  @override
  Future<int> updateById(int id, ProductsCompanion companion) async {
    throw Exception('boom');
  }
}

void main() {
  late AppDatabase db;
  late OrderRepository repo;

  const shipping = ShippingInfo(
    name: 'Amira Hassan',
    phone: '0100 000 0001',
    address: '14 Nile St, Cairo',
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = OrderRepositoryImpl(
      OrderDao(db),
      ProductDao(db),
      CartDao(db),
      CouponDao(db),
      ProductMapper(),
      OrderMapper(),
      CouponMapper(),
      db,
    );
  });

  tearDown(() => db.close());

  Future<int> insertCategory(String name) => db.into(db.categories).insert(
        CategoriesCompanion.insert(name: name, createdAt: 1),
      );

  Future<int> insertProduct(
    int categoryId,
    String name, {
    String? nameAr,
    int priceCents = 1000,
    int discountPercent = 0,
    int stock = 10,
  }) {
    return db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: name,
          nameAr: Value(nameAr),
          priceCents: priceCents,
          discountPercent: discountPercent,
          stock: stock,
          createdAt: 1,
          updatedAt: 1,
        ));
  }

  Future<void> addToCart(int productId, int quantity) async {
    final result =
        await CartRepositoryImpl(CartDao(db)).setQuantity(productId, quantity);
    expect(result, isA<Success<void>>());
  }

  Future<int> placeOrder({
    ShippingInfo withShipping = shipping,
    String? couponCode,
  }) async {
    final result = await repo.placeOrder(withShipping, couponCode: couponCode);
    expect(result, isA<Success<Order>>());
    return result.getOrThrow().id;
  }

  /// Inserts a coupon row directly (the repository under test is
  /// OrderRepositoryImpl — the coupon's own CRUD is covered elsewhere).
  Future<int> insertCoupon({
    String code = 'SAVE10',
    CouponDiscountType type = CouponDiscountType.percent,
    int value = 10,
    int minSpendCents = 0,
    DateTime? expiresAt,
    int? maxUses,
    int usedCount = 0,
    bool isActive = true,
  }) {
    return db.into(db.coupons).insert(CouponsCompanion.insert(
          code: code,
          discountType: type,
          value: value,
          minSpendCents: Value(minSpendCents),
          expiresAt: Value(expiresAt?.millisecondsSinceEpoch),
          maxUses: Value(maxUses),
          usedCount: Value(usedCount),
          isActive: Value(isActive),
          createdAt: 1,
        ));
  }

  Future<CouponRow> couponRow(String code) async {
    return (db.select(db.coupons)..where((t) => t.code.equals(code)))
        .getSingle();
  }

  group('placeOrder', () {
    test('creates a pending order with snapshot items and shipping', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt',
          nameAr: 'تيشيرت', priceCents: 2000, discountPercent: 25);
      await addToCart(productId, 2);

      final result = await repo.placeOrder(shipping);

      final order = result.getOrThrow();
      expect(order.orderNumber, matches(RegExp(r'^ORD-\d{6}$')));
      expect(order.status, OrderStatus.pending);
      expect(order.shipping, shipping);
      expect(order.createdAt, isNotNull);
      expect(order.updatedAt, isNotNull);

      final item = order.items.single;
      expect(item.productId, productId);
      expect(item.productName, 'T-Shirt');
      expect(item.productNameAr, 'تيشيرت',
          reason: 'the receipt snapshot carries both labels');
      expect(item.unitPriceCents, 2000);
      expect(item.discountPercent, 25);
      expect(item.quantity, 2);

      expect(order.statusHistory.map((e) => e.status), [OrderStatus.pending]);
    });

    test('computes snapshot totals with the domain integer money math', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug',
          priceCents: 1000, discountPercent: 10);
      await addToCart(productId, 3);

      final order = (await repo.placeOrder(shipping)).getOrThrow();

      // 1000 x 3 subtotal; 10% of 1000 = 100 saved per unit x 3.
      expect(order.subtotalCents, 3000);
      expect(order.discountCents, 300);
      expect(order.totalCents, 2700);
      expect(order.subtotalCents - order.discountCents, order.totalCents);
      // The per-line totals must sum to the order total (the invariant the
      // order detail UI renders from). Holds because discountAmountCents is
      // defined as price - discountedPrice (shared integer math).
      expect(
        order.items.fold(0, (sum, item) => sum + item.lineTotalCents),
        order.totalCents,
      );
    });

    test('decrements stock and clears the cart', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt', stock: 5);
      await addToCart(productId, 2);

      await placeOrder();

      final product =
          await (db.select(db.products)..where((t) => t.id.equals(productId)))
              .getSingle();
      expect(product.stock, 3);
      expect(await (db.select(db.cartItems)).get(), isEmpty);
    });

    test('yields ValidationError for an empty cart', () async {
      final result = await repo.placeOrder(shipping);
      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<ValidationError>());
    });

    test('yields ValidationError for insufficient stock and writes nothing',
        () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt', stock: 1);
      await addToCart(productId, 2);

      final result = await repo.placeOrder(shipping);

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<ValidationError>());
      expect(await (db.select(db.orders)).get(), isEmpty,
          reason: 'no order may exist after a failed placement');
      expect(await (db.select(db.orderItems)).get(), isEmpty);
      expect(await (db.select(db.orderStatusHistory)).get(), isEmpty);
      expect((await db.select(db.cartItems).get()).single.quantity, 2,
          reason: 'the cart must survive a failed placement');
      final product =
          await (db.select(db.products)..where((t) => t.id.equals(productId)))
              .getSingle();
      expect(product.stock, 1);
    });

    test('rolls back a partially-written transaction atomically', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt', stock: 5);
      await addToCart(productId, 2);

      // The exploding DAO fails on the stock decrement — the write that
      // happens AFTER the order + items are already inserted.
      final explodingRepo = OrderRepositoryImpl(
        OrderDao(db),
        _ExplodingProductDao(db),
        CartDao(db),
        CouponDao(db),
        ProductMapper(),
        OrderMapper(),
        CouponMapper(),
        db,
      );

      final result = await explodingRepo.placeOrder(shipping);

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<DatabaseError>());
      expect(await (db.select(db.orders)).get(), isEmpty,
          reason: 'the inserted order must be rolled back');
      expect(await (db.select(db.orderItems)).get(), isEmpty);
      expect(await (db.select(db.orderStatusHistory)).get(), isEmpty);
      expect((await db.select(db.cartItems).get()).single.quantity, 2,
          reason: 'the cart clear (last step) must also be rolled back');
      final product =
          await (db.select(db.products)..where((t) => t.id.equals(productId)))
              .getSingle();
      expect(product.stock, 5, reason: 'stock decrement must be rolled back');
    });

    // --- Coupons -----------------------------------------------------------

    test('applies a valid coupon: snapshot fields, totals, and usedCount',
        () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug',
          priceCents: 1000, stock: 10);
      await addToCart(productId, 4); // subtotal 4000
      await insertCoupon(code: 'SAVE10', value: 10);

      // Lowercase input: the placement normalizes before looking up.
      final order =
          (await repo.placeOrder(shipping, couponCode: 'save10')).getOrThrow();

      expect(order.subtotalCents, 4000);
      expect(order.couponCode, 'SAVE10', reason: 'normalized snapshot');
      expect(order.couponDiscountCents, 400);
      expect(order.discountCents, 400, reason: 'the coupon is the only source');
      expect(order.totalCents, 3600);
      // The usage counter increments atomically with the order.
      expect((await couponRow('SAVE10')).usedCount, 1);
    });

    test('the coupon discount stacks on top of the line savings', () async {
      final categoryId = await insertCategory('Clothing');
      // 10% line discount: 2000 x 2 subtotal = 4000, savings = 400.
      final productId = await insertProduct(categoryId, 'Mug',
          priceCents: 2000, discountPercent: 10, stock: 10);
      await addToCart(productId, 2);
      await insertCoupon(code: 'SAVE10', value: 10);

      final order =
          (await repo.placeOrder(shipping, couponCode: 'SAVE10')).getOrThrow();

      // Eligible spend is line-discounted: 4000 - 400 = 3600 -> 10% = 360.
      expect(order.couponDiscountCents, 360);
      expect(order.discountCents, 400 + 360);
      expect(order.totalCents, 4000 - 400 - 360);
    });

    test('a fixed coupon larger than the subtotal is capped at it', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug',
          priceCents: 1000, stock: 10);
      await addToCart(productId, 1);
      await insertCoupon(code: 'BIG', type: CouponDiscountType.fixed, value: 5000);

      final order =
          (await repo.placeOrder(shipping, couponCode: 'BIG')).getOrThrow();

      expect(order.couponDiscountCents, 1000, reason: 'capped at the subtotal');
      expect(order.totalCents, 0, reason: 'the total never goes negative');
    });

    test('an unknown coupon code rejects the order and writes nothing',
        () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug', stock: 10);
      await addToCart(productId, 1);

      final result = await repo.placeOrder(shipping, couponCode: 'NOPE');

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<CouponNotFoundError>());
      expect(await (db.select(db.orders)).get(), isEmpty,
          reason: 'no order may exist after a rejected placement');
      expect((await db.select(db.cartItems).get()).single.quantity, 1,
          reason: 'the cart must survive');
    });

    test('an expired coupon rejects the order', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug', stock: 10);
      await addToCart(productId, 1);
      await insertCoupon(
        code: 'OLD',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final result = await repo.placeOrder(shipping, couponCode: 'OLD');

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<CouponExpiredError>());
    });

    test('an unmet minimum spend rejects the order', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug',
          priceCents: 1000, stock: 10);
      await addToCart(productId, 4); // subtotal 4000 < min 5000
      await insertCoupon(code: 'BIG', minSpendCents: 5000);

      final result = await repo.placeOrder(shipping, couponCode: 'BIG');

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<CouponMinSpendError>());
    });

    test('an exhausted usage cap rejects the order', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug', stock: 10);
      await addToCart(productId, 1);
      await insertCoupon(code: 'FULL', maxUses: 2, usedCount: 2);

      final result = await repo.placeOrder(shipping, couponCode: 'FULL');

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<CouponUsageLimitError>());
    });

    test('an inactive coupon rejects the order', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'Mug', stock: 10);
      await addToCart(productId, 1);
      await insertCoupon(code: 'OFF', isActive: false);

      final result = await repo.placeOrder(shipping, couponCode: 'OFF');

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<CouponInactiveError>());
    });

    test('a used coupon rolls back with a failed placement', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt', stock: 5);
      await addToCart(productId, 2);
      await insertCoupon(code: 'SAVE10', value: 10);

      final explodingRepo = OrderRepositoryImpl(
        OrderDao(db),
        _ExplodingProductDao(db),
        CartDao(db),
        CouponDao(db),
        ProductMapper(),
        OrderMapper(),
        CouponMapper(),
        db,
      );
      final result =
          await explodingRepo.placeOrder(shipping, couponCode: 'SAVE10');

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<DatabaseError>());
      expect((await couponRow('SAVE10')).usedCount, 0,
          reason: 'the usage increment must roll back with the order');
      expect(await (db.select(db.orders)).get(), isEmpty);
    });
  });

  group('updateStatus', () {
    test('moves through legal transitions and appends history', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt');
      await addToCart(productId, 1);
      final orderId = await placeOrder();
      final firstUpdatedAt = (await repo.getById(orderId)).getOrThrow().updatedAt;

      final confirmed = (await repo.updateStatus(orderId, OrderStatus.confirmed))
          .getOrThrow();
      expect(confirmed.status, OrderStatus.confirmed);
      expect(
        confirmed.statusHistory.map((e) => e.status),
        [OrderStatus.pending, OrderStatus.confirmed],
      );
      expect(confirmed.updatedAt!.isAfter(firstUpdatedAt!), isTrue);

      final shipped =
          (await repo.updateStatus(orderId, OrderStatus.shipped)).getOrThrow();
      expect(shipped.status, OrderStatus.shipped);

      final delivered =
          (await repo.updateStatus(orderId, OrderStatus.delivered)).getOrThrow();
      expect(delivered.status, OrderStatus.delivered);
      expect(delivered.statusHistory, hasLength(4));
      expect(delivered.items.single.productName, 'T-Shirt',
          reason: 'the aggregate must survive transitions');
    });

    test('allows cancellation from confirmed and locks it at delivered',
        () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt');
      await addToCart(productId, 1);
      final orderId = await placeOrder();

      final cancelled =
          (await repo.updateStatus(orderId, OrderStatus.cancelled)).getOrThrow();
      expect(cancelled.status, OrderStatus.cancelled);

      final again = await repo.updateStatus(orderId, OrderStatus.confirmed);
      expect(again, isA<Failure<Order>>());
      expect((again as Failure<Order>).error, isA<ValidationError>());
    });

    test('rejects illegal and same-status transitions', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt');
      await addToCart(productId, 1);
      final orderId = await placeOrder();

      // Same-status move is rejected (no no-op transitions).
      final same = await repo.updateStatus(orderId, OrderStatus.pending);
      expect(same, isA<Failure<Order>>());
      expect((same as Failure<Order>).error, isA<ValidationError>());

      // pending -> delivered skips the state machine.
      final skip = await repo.updateStatus(orderId, OrderStatus.delivered);
      expect(skip, isA<Failure<Order>>());
      expect((skip as Failure<Order>).error, isA<ValidationError>());

      // The failed attempts must not have written history rows.
      final order = (await repo.getById(orderId)).getOrThrow();
      expect(order.statusHistory, hasLength(1));
      expect(order.status, OrderStatus.pending);
    });

    test('yields NotFoundError for a missing order', () async {
      final result = await repo.updateStatus(999, OrderStatus.confirmed);
      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<NotFoundError>());
    });
  });

  group('reads and streams', () {
    test('getById returns the full aggregate with items and history',
        () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt');
      await addToCart(productId, 1);
      final orderId = await placeOrder();
      await repo.updateStatus(orderId, OrderStatus.confirmed);

      final order = (await repo.getById(orderId)).getOrThrow();

      expect(order.items, hasLength(1));
      expect(order.items.single.productName, 'T-Shirt');
      expect(
        order.statusHistory.map((e) => e.status),
        [OrderStatus.pending, OrderStatus.confirmed],
      );
      expect(order.statusHistory.last.changedAt, order.updatedAt);
    });

    test('watchOrders emits the list and re-emits on status change', () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt');
      await addToCart(productId, 1);
      final orderId = await placeOrder();

      final done = expectLater(
        repo.watchOrders(),
        emitsInOrder([
          isA<List<Order>>().having(
              (orders) => orders.single.status, 'status', OrderStatus.pending),
          isA<List<Order>>().having((orders) => orders.single.status, 'status',
              OrderStatus.confirmed),
        ]),
      );

      await pumpEventQueue();
      await repo.updateStatus(orderId, OrderStatus.confirmed);

      await done;
    });

    test('watchOrderById emits the aggregate, then null after deletion',
        () async {
      final categoryId = await insertCategory('Clothing');
      final productId = await insertProduct(categoryId, 'T-Shirt');
      await addToCart(productId, 1);
      final orderId = await placeOrder();

      final done = expectLater(
        repo.watchOrderById(orderId),
        emitsInOrder([
          isA<Order>().having((o) => o.items.length, 'has an item', 1),
          isNull,
        ]),
      );

      await pumpEventQueue();
      // Orders are never deleted through the app; the cascade still applies.
      await (db.delete(db.orders)..where((t) => t.id.equals(orderId))).go();

      await done;
    });

    test('getById yields NotFoundError for a missing order', () async {
      final result = await repo.getById(999);
      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<NotFoundError>());
    });
  });
}

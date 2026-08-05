import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/domain/repositories/order_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/presentation/features/admin/overview/admin_overview_cubit.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockOrderRepository orders;
  late MockProductRepository products;
  late StreamController<List<Order>> ordersCtrl;
  late StreamController<List<Product>> productsCtrl;

  const shipping = ShippingInfo(name: 'A', phone: '1', address: 'St');
  Order order(int id, OrderStatus status, int total) => Order(
        id: id,
        orderNumber: 'ORD-${id.toString().padLeft(6, '0')}',
        status: status,
        subtotalCents: total,
        discountCents: 0,
        totalCents: total,
        shipping: shipping,
      );

  setUp(() {
    orders = MockOrderRepository();
    products = MockProductRepository();
    // Synchronous broadcast controllers: emissions land immediately, and only
    // after the cubit has subscribed (broadcast drops early emissions).
    ordersCtrl = StreamController<List<Order>>.broadcast(sync: true);
    productsCtrl = StreamController<List<Product>>.broadcast(sync: true);
    when(() => orders.watchOrders()).thenAnswer((_) => ordersCtrl.stream);
    when(() => products.watchProducts()).thenAnswer((_) => productsCtrl.stream);
  });

  tearDown(() async {
    await ordersCtrl.close();
    await productsCtrl.close();
  });

  AdminOverviewCubit buildCubit() =>
      AdminOverviewCubit(orders, products);

  test('starts loading and emits loaded once both streams have emitted', () {
    final cubit = buildCubit();
    expect(cubit.state, isA<AdminOverviewLoading>());

    ordersCtrl.add(const []);
    expect(cubit.state, isA<AdminOverviewLoading>()); // products not yet

    productsCtrl.add(const []);
    expect(cubit.state, isA<AdminOverviewLoaded>());

    cubit.close();
  });

  test('revenue sums non-cancelled order totals, count excludes nothing', () {
    final cubit = buildCubit();
    ordersCtrl.add([
      order(1, OrderStatus.pending, 1000),
      order(2, OrderStatus.confirmed, 2000),
      order(3, OrderStatus.delivered, 3000),
      order(4, OrderStatus.cancelled, 9999), // NOT revenue
      order(5, OrderStatus.shipped, 4000),
      order(6, OrderStatus.pending, 500),
    ]);
    productsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(loaded.revenueCents, 10500);
    expect(loaded.totalOrders, 6);

    cubit.close();
  });

  test('ordersByStatus is zero-filled and counts correctly', () {
    final cubit = buildCubit();
    ordersCtrl.add([
      order(1, OrderStatus.pending, 1000),
      order(2, OrderStatus.delivered, 2000),
    ]);
    productsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    // Every status present — zero-filled — so the chart axis is stable.
    expect(loaded.ordersByStatus.keys, containsAll(OrderStatus.values));
    expect(loaded.ordersByStatus[OrderStatus.pending], 1);
    expect(loaded.ordersByStatus[OrderStatus.delivered], 1);
    expect(loaded.ordersByStatus[OrderStatus.shipped], 0);

    cubit.close();
  });

  test('recentOrders is capped at the dashboard limit', () {
    final cubit = buildCubit();
    ordersCtrl.add([
      for (var i = 1; i <= 7; i++)
        order(i, OrderStatus.pending, 1000),
    ]);
    productsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(loaded.recentOrders, hasLength(AdminOverviewLoaded.recentLimit));
    expect(loaded.recentOrders.first.id, 1); // stream order preserved

    cubit.close();
  });

  test('lowStockProducts lists only low/out items, most critical first', () {
    final cubit = buildCubit();
    ordersCtrl.add(const []);
    productsCtrl.add(const [
      Product(id: 1, categoryId: 1, name: 'Fine', priceCents: 100, stock: 10),
      Product(id: 2, categoryId: 1, name: 'Low', priceCents: 100, stock: 3),
      Product(id: 3, categoryId: 1, name: 'Out', priceCents: 100, stock: 0),
    ]);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(loaded.lowStockProducts.map((p) => p.name), ['Out', 'Low']);

    cubit.close();
  });

  test('a stream error becomes AdminOverviewError and is sticky', () {
    final cubit = buildCubit();
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    expect(cubit.state, isA<AdminOverviewLoaded>());

    ordersCtrl.addError(StateError('boom'));
    expect(cubit.state, isA<AdminOverviewError>());

    productsCtrl.add(const []);
    expect(cubit.state, isA<AdminOverviewError>());

    cubit.close();
  });

  test('close cancels the stream subscriptions', () async {
    final cubit = buildCubit();
    cubit.close();
    expect(ordersCtrl.hasListener, isFalse);
    expect(productsCtrl.hasListener, isFalse);
  });
}

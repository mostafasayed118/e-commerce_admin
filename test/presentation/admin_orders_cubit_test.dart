import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/order_repository.dart';
import 'package:shop_admin/presentation/features/admin/orders/admin_orders_cubit.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository repository;
  late StreamController<List<Order>> ordersCtrl;

  const pending = Order(
    id: 1,
    orderNumber: 'ORD-000001',
    status: OrderStatus.pending,
    subtotalCents: 1000,
    discountCents: 0,
    totalCents: 1000,
    shipping: ShippingInfo(name: 'A', phone: '1', address: 'St'),
  );
  const delivered = Order(
    id: 2,
    orderNumber: 'ORD-000002',
    status: OrderStatus.delivered,
    subtotalCents: 2000,
    discountCents: 0,
    totalCents: 2000,
    shipping: ShippingInfo(name: 'B', phone: '2', address: 'Ave'),
  );

  setUp(() {
    repository = MockOrderRepository();
    // Synchronous broadcast controller: emissions land immediately, and only
    // after the cubit has subscribed (broadcast drops early emissions).
    ordersCtrl = StreamController<List<Order>>.broadcast(sync: true);
    when(() => repository.watchOrders()).thenAnswer((_) => ordersCtrl.stream);
  });

  tearDown(() async {
    await ordersCtrl.close();
  });

  test('starts loading and emits loaded once the stream has emitted', () {
    final cubit = AdminOrdersCubit(repository);
    expect(cubit.state, isA<AdminOrdersLoading>());

    ordersCtrl.add(const [pending, delivered]);
    final loaded = cubit.state as AdminOrdersLoaded;
    expect(loaded.allOrders, hasLength(2));
    expect(loaded.filter, isNull);
    expect(loaded.visibleOrders, hasLength(2));

    cubit.close();
  });

  test('setFilter recomputes the visible list, null clears it', () {
    final cubit = AdminOrdersCubit(repository);
    ordersCtrl.add(const [pending, delivered]);

    cubit.setFilter(OrderStatus.pending);
    var loaded = cubit.state as AdminOrdersLoaded;
    expect(loaded.visibleOrders, [pending]);

    cubit.setFilter(OrderStatus.delivered);
    loaded = cubit.state as AdminOrdersLoaded;
    expect(loaded.visibleOrders, [delivered]);

    cubit.setFilter(null);
    loaded = cubit.state as AdminOrdersLoaded;
    expect(loaded.visibleOrders, hasLength(2));

    cubit.close();
  });

  test('setQuery matches order number (hyphen-insensitive), name, and phone',
      () {
    final cubit = AdminOrdersCubit(repository);
    ordersCtrl.add(const [pending, delivered]);

    // 'ORD-1' (with hyphen) and 'ord1' (without) both find ORD-000001.
    cubit.setQuery('ORD-1');
    expect((cubit.state as AdminOrdersLoaded).visibleOrders, [pending]);
    cubit.setQuery('ord1');
    expect((cubit.state as AdminOrdersLoaded).visibleOrders, [pending]);

    // Customer name and phone match too.
    cubit.setQuery('A');
    expect((cubit.state as AdminOrdersLoaded).visibleOrders, [pending]);
    cubit.setQuery('2');
    expect((cubit.state as AdminOrdersLoaded).visibleOrders, [delivered]);

    // No match -> empty, but distinguishable from "no orders at all".
    cubit.setQuery('zzz');
    final noMatch = cubit.state as AdminOrdersLoaded;
    expect(noMatch.visibleOrders, isEmpty);
    expect(noMatch.hasActiveFilter, isTrue);

    cubit.setQuery('');
    final cleared = cubit.state as AdminOrdersLoaded;
    expect(cleared.visibleOrders, hasLength(2));
    expect(cleared.hasActiveFilter, isFalse);

    cubit.close();
  });

  test('setDateRange is inclusive over whole days and excludes null createdAt',
      () {
    final cubit = AdminOrdersCubit(repository);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdays = Order(
      id: 3,
      orderNumber: 'ORD-000003',
      status: OrderStatus.pending,
      subtotalCents: 3000,
      discountCents: 0,
      totalCents: 3000,
      shipping: const ShippingInfo(name: 'C', phone: '3', address: 'Rd'),
      createdAt: yesterday,
    );
    ordersCtrl.add([pending, delivered, yesterdays]);

    // From today: pending/delivered carry no createdAt (excluded by any
    // date filter) and yesterdays predates today -> nothing remains.
    cubit.setDateRange(from: DateTime.now());
    expect((cubit.state as AdminOrdersLoaded).visibleOrders, isEmpty);

    // A single-day window on yesterday keeps exactly that order.
    cubit.setDateRange(from: yesterday, to: yesterday);
    expect((cubit.state as AdminOrdersLoaded).visibleOrders, [yesterdays]);

    // Clearing both bounds restores everything.
    cubit.setDateRange(from: null, to: null);
    final cleared = cubit.state as AdminOrdersLoaded;
    expect(cleared.visibleOrders, hasLength(3));
    expect(cleared.hasActiveFilter, isFalse);

    cubit.close();
  });

  test('combined filters AND together; clearFilters resets all', () {
    final cubit = AdminOrdersCubit(repository);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdays = Order(
      id: 3,
      orderNumber: 'ORD-000003',
      status: OrderStatus.pending,
      subtotalCents: 3000,
      discountCents: 0,
      totalCents: 3000,
      shipping: const ShippingInfo(name: 'C', phone: '3', address: 'Rd'),
      createdAt: yesterday,
    );
    ordersCtrl.add([pending, delivered, yesterdays]);

    cubit.setFilter(OrderStatus.pending);
    cubit.setQuery('000003');
    cubit.setDateRange(from: yesterday, to: yesterday);
    expect((cubit.state as AdminOrdersLoaded).visibleOrders, [yesterdays]);

    cubit.clearFilters();
    final cleared = cubit.state as AdminOrdersLoaded;
    expect(cleared.visibleOrders, hasLength(3));
    expect(cleared.filter, isNull);
    expect(cleared.query, isEmpty);
    expect(cleared.fromDate, isNull);
    expect(cleared.toDate, isNull);
    expect(cleared.hasActiveFilter, isFalse);

    cubit.close();
  });

  test('a stream error becomes AdminOrdersError and is sticky', () {
    final cubit = AdminOrdersCubit(repository);
    ordersCtrl.add(const [pending]);
    expect(cubit.state, isA<AdminOrdersLoaded>());

    ordersCtrl.addError(StateError('boom'));
    expect(cubit.state, isA<AdminOrdersError>());

    // Later emissions (and setFilter) must not resurrect the loaded state.
    ordersCtrl.add(const [pending, delivered]);
    cubit.setFilter(OrderStatus.pending);
    expect(cubit.state, isA<AdminOrdersError>());

    cubit.close();
  });

  test('updateStatus delegates to the repository and returns its result',
      () async {
    final cubit = AdminOrdersCubit(repository);
    const confirmed = Order(
      id: 1,
      orderNumber: 'ORD-000001',
      status: OrderStatus.confirmed,
      subtotalCents: 1000,
      discountCents: 0,
      totalCents: 1000,
      shipping: ShippingInfo(name: 'A', phone: '1', address: 'St'),
    );
    when(() => repository.updateStatus(1, OrderStatus.confirmed))
        .thenAnswer((_) async => const Success(confirmed));

    final result = await cubit.updateStatus(1, OrderStatus.confirmed);

    expect(result.isSuccess, isTrue);
    expect((result as Success<Order>).value.status, OrderStatus.confirmed);
    verify(() => repository.updateStatus(1, OrderStatus.confirmed)).called(1);
    cubit.close();
  });

  test('close cancels the stream subscription', () async {
    final cubit = AdminOrdersCubit(repository);
    cubit.close();
    expect(ordersCtrl.hasListener, isFalse);
  });
}

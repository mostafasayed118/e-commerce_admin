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

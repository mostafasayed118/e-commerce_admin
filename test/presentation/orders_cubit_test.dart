import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/domain/repositories/order_repository.dart';
import 'package:shop_admin/presentation/features/orders/orders_cubit.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository repository;
  late StreamController<List<Order>> ordersCtrl;

  const order = Order(
    id: 1,
    orderNumber: 'ORD-000001',
    status: OrderStatus.delivered,
    subtotalCents: 6800,
    discountCents: 1000,
    totalCents: 5800,
    shipping: ShippingInfo(name: 'A', phone: '1', address: 'St'),
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
    final cubit = OrdersCubit(repository);
    expect(cubit.state, isA<OrdersLoading>());

    ordersCtrl.add(const [order]);
    final loaded = cubit.state as OrdersLoaded;
    expect(loaded.orders, [order]);

    cubit.close();
  });

  test('an empty history is a loaded state (the screen shows the empty view)',
      () {
    final cubit = OrdersCubit(repository);
    ordersCtrl.add(const []);

    expect(cubit.state, isA<OrdersLoaded>());
    expect((cubit.state as OrdersLoaded).orders, isEmpty);

    cubit.close();
  });

  test('a stream error becomes OrdersError and is sticky', () {
    final cubit = OrdersCubit(repository);
    ordersCtrl.add(const [order]);
    expect(cubit.state, isA<OrdersLoaded>());

    ordersCtrl.addError(StateError('boom'));
    expect(cubit.state, isA<OrdersError>());

    // A later emission must not resurrect the loaded state.
    ordersCtrl.add(const [order]);
    expect(cubit.state, isA<OrdersError>());

    cubit.close();
  });

  test('close cancels the stream subscription', () async {
    final cubit = OrdersCubit(repository);
    cubit.close();
    expect(ordersCtrl.hasListener, isFalse);
  });
}

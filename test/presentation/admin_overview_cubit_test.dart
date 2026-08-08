import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/domain/repositories/coupon_repository.dart';
import 'package:shop_admin/domain/repositories/order_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/presentation/features/admin/overview/admin_overview_cubit.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockCouponRepository extends Mock implements CouponRepository {}

void main() {
  late MockOrderRepository orders;
  late MockProductRepository products;
  late MockCouponRepository coupons;
  late StreamController<List<Order>> ordersCtrl;
  late StreamController<List<Product>> productsCtrl;
  late StreamController<List<Coupon>> couponsCtrl;

  const shipping = ShippingInfo(name: 'A', phone: '1', address: 'St');
  Order order(
    int id,
    OrderStatus status,
    int total, {
    String? couponCode,
    int couponDiscountCents = 0,
    DateTime? createdAt,
    List<OrderItem> items = const [],
  }) =>
      Order(
        id: id,
        orderNumber: 'ORD-${id.toString().padLeft(6, '0')}',
        status: status,
        subtotalCents: total,
        discountCents: couponCode == null ? 0 : couponDiscountCents,
        totalCents: total - (couponCode == null ? 0 : couponDiscountCents),
        couponCode: couponCode,
        couponDiscountCents: couponDiscountCents,
        shipping: shipping,
        items: items,
        createdAt: createdAt,
      );

  Coupon coupon(
    int id,
    String code, {
    bool isActive = true,
    DateTime? expiresAt,
    int usedCount = 0,
    int? maxUses,
  }) =>
      Coupon(
        id: id,
        code: code,
        type: CouponDiscountType.percent,
        value: 10,
        isActive: isActive,
        expiresAt: expiresAt,
        usedCount: usedCount,
        maxUses: maxUses,
      );

  setUp(() {
    orders = MockOrderRepository();
    products = MockProductRepository();
    coupons = MockCouponRepository();
    // Synchronous broadcast controllers: emissions land immediately, and only
    // after the cubit has subscribed (broadcast drops early emissions).
    ordersCtrl = StreamController<List<Order>>.broadcast(sync: true);
    productsCtrl = StreamController<List<Product>>.broadcast(sync: true);
    couponsCtrl = StreamController<List<Coupon>>.broadcast(sync: true);
    when(() => orders.watchOrders()).thenAnswer((_) => ordersCtrl.stream);
    when(() => products.watchProducts()).thenAnswer((_) => productsCtrl.stream);
    when(() => coupons.watchCoupons()).thenAnswer((_) => couponsCtrl.stream);
  });

  tearDown(() async {
    await ordersCtrl.close();
    await productsCtrl.close();
    await couponsCtrl.close();
  });

  AdminOverviewCubit buildCubit({DateTime Function()? now}) =>
      AdminOverviewCubit(orders, products, coupons, now: now ?? DateTime.now);

  test('starts loading and emits loaded once all three streams have emitted',
      () {
    final cubit = buildCubit();
    expect(cubit.state, isA<AdminOverviewLoading>());

    ordersCtrl.add(const []);
    expect(cubit.state, isA<AdminOverviewLoading>()); // products not yet

    productsCtrl.add(const []);
    expect(cubit.state, isA<AdminOverviewLoading>()); // coupons not yet

    couponsCtrl.add(const []);
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
    couponsCtrl.add(const []);

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
    couponsCtrl.add(const []);

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
    couponsCtrl.add(const []);

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
    couponsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(loaded.lowStockProducts.map((p) => p.name), ['Out', 'Low']);

    cubit.close();
  });

  test('activeCouponCount counts active unexpired coupons at the injected now',
      () {
    final fixed = DateTime(2026, 7, 15);
    final cubit = buildCubit(now: () => fixed);
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    couponsCtrl.add([
      coupon(1, 'NO-EXPIRY'), // active, never expires
      coupon(2, 'INACTIVE', isActive: false), // disabled
      coupon(3, 'PAST',
          expiresAt: fixed.subtract(const Duration(days: 1))), // expired
      coupon(4, 'FUTURE',
          expiresAt: fixed.add(const Duration(days: 30))), // active, future
      coupon(5, 'TODAY', expiresAt: fixed), // expires exactly now — expired
    ]);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(loaded.activeCouponCount, 2);

    cubit.close();
  });

  test('recentCouponUses lists coupon-bearing orders newest first, capped', () {
    final cubit = buildCubit();
    // The orders stream is newest-first (repository contract), so the list
    // is emitted most-recent-first and the cubit preserves that order.
    ordersCtrl.add([
      order(7, OrderStatus.pending, 1500,
          couponCode: 'SAVE5', couponDiscountCents: 500),
      order(6, OrderStatus.pending, 1500,
          couponCode: 'SAVE5', couponDiscountCents: 500),
      order(3, OrderStatus.pending, 1500,
          couponCode: 'WELCOME10', couponDiscountCents: 150),
      order(5, OrderStatus.pending, 1500,
          couponCode: 'SAVE5', couponDiscountCents: 500),
      order(4, OrderStatus.pending, 1500,
          couponCode: 'SAVE5', couponDiscountCents: 500),
      order(2, OrderStatus.pending, 1500,
          couponCode: 'SAVE5', couponDiscountCents: 500),
      order(1, OrderStatus.pending, 1000), // no coupon — skipped
    ]);
    productsCtrl.add(const []);
    couponsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    // Newest-first (stream order preserved), capped like recent orders.
    expect(loaded.recentCouponUses, hasLength(AdminOverviewLoaded.couponUsesLimit));
    expect(loaded.recentCouponUses.map((u) => u.orderId), [7, 6, 3, 5]);
    expect(loaded.recentCouponUses.first.code, 'SAVE5');
    expect(
      loaded.recentCouponUses.any((u) => u.code == 'WELCOME10'),
      isTrue,
      reason: 'id 3 was cut only by the cap, not by filtering',
    );
    expect(
      loaded.recentCouponUses.any((u) => u.orderId == 1),
      isFalse,
      reason: 'orders without a coupon never appear',
    );

    cubit.close();
  });  test('topCoupons ranks uncapped coupons by count with a relative bar',
      () {
    final cubit = buildCubit();
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    couponsCtrl.add([
      coupon(1, 'ZERO'), // no redemptions — never ranks
      coupon(2, 'AAA', usedCount: 1),
      coupon(3, 'BBB', usedCount: 3),
      coupon(4, 'CCC', usedCount: 2),
      coupon(5, 'DDD', usedCount: 1),
    ]);

    final loaded = cubit.state as AdminOverviewLoaded;
    // Count desc, ties alphabetical (AAA before DDD); zero-usage excluded.
    expect(loaded.topCoupons.map((t) => t.code), ['BBB', 'CCC', 'AAA', 'DDD']);
    expect(loaded.topCoupons.first.fraction, 1.0);
    expect(loaded.topCoupons[1].fraction, closeTo(2 / 3, 0.001));
    expect(loaded.topCoupons[2].fraction, closeTo(1 / 3, 0.001));
    expect(
      loaded.topCoupons.any((t) => t.code == 'ZERO'),
      isFalse,
      reason: 'coupons with no redemptions never rank',
    );

    cubit.close();
  });

  test('topCoupons ranks capped coupons by exhaustion, then uncapped by count',
      () {
    final cubit = buildCubit();
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    couponsCtrl.add([
      coupon(1, 'UNLIMITED', usedCount: 4), // uncapped → ranked after
      coupon(2, 'CAPPED', usedCount: 3, maxUses: 5), // 60% of the cap
      coupon(3, 'FULL', usedCount: 2, maxUses: 2), // at the cap → 1.0
      // Over-cap: reachable when an admin lowers a cap below past
      // redemptions — the bar must clamp to 1.0, never overflow.
      coupon(4, 'OVERCAPPED', usedCount: 4, maxUses: 3),
    ]);

    final loaded = cubit.state as AdminOverviewLoaded;
    // Capped coupons rank first by exhaustion %: OVERCAPPED (133%) → FULL
    // (100%) → CAPPED (60%); unlimited coupons follow by count. FULL outranks
    // CAPPED despite fewer redemptions — closeness to exhaustion wins.
    expect(
      loaded.topCoupons.map((t) => t.code),
      ['OVERCAPPED', 'FULL', 'CAPPED', 'UNLIMITED'],
    );
    expect(loaded.topCoupons[0].fraction, 1.0,
        reason: 'over the cap the bar clamps, it never overflows');
    expect(loaded.topCoupons[0].maxUses, 3);
    expect(loaded.topCoupons[1].fraction, 1.0); // 2/2 at the cap
    expect(loaded.topCoupons[1].maxUses, 2);
    expect(loaded.topCoupons[2].fraction, 0.6, reason: '3 of 5 uses');
    expect(loaded.topCoupons[2].maxUses, 5);
    expect(loaded.topCoupons[3].fraction, 1.0,
        reason: '4 uses vs the top count of 4');
    expect(loaded.topCoupons[3].maxUses, isNull);

    cubit.close();
  });

  test('topCoupons ranks capped coupons by exhaustion, not raw count', () {
    final cubit = buildCubit();
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    couponsCtrl.add([
      // Fewer uses but a smaller cap → higher exhaustion → ranks above
      // the bigger-cap coupon despite fewer redemptions.
      coupon(1, 'SMALLCAP', usedCount: 3, maxUses: 4), // 75%
      coupon(2, 'BIGCAP', usedCount: 8, maxUses: 20), // 40%
      // Unlimited and the most used — still ranks below any capped coupon.
      coupon(3, 'HEAVY', usedCount: 100),
      // Same exhaustion as SMALLCAP → alphabetical tie-break.
      coupon(4, 'TIE', usedCount: 6, maxUses: 8), // 75%
    ]);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(
      loaded.topCoupons.map((t) => t.code),
      ['SMALLCAP', 'TIE', 'BIGCAP', 'HEAVY'],
    );
    expect(loaded.topCoupons[0].fraction, 0.75);
    expect(loaded.topCoupons[1].fraction, 0.75,
        reason: 'equal exhaustion → alphabetical tie-break');
    expect(loaded.topCoupons[2].fraction, 0.4);
    expect(loaded.topCoupons[3].fraction, 1.0,
        reason: 'HEAVY is the top count, so its relative bar is full');

    cubit.close();
  });

  test('topCoupons is capped at the ranking limit', () {
    final cubit = buildCubit();
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    couponsCtrl.add([
      for (var i = 1; i <= 6; i++)
        coupon(i, 'C$i', usedCount: i),
    ]);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(loaded.topCoupons, hasLength(AdminOverviewLoaded.topCouponsLimit));
    expect(loaded.topCoupons.first.code, 'C6');

    cubit.close();
  });

  test('dailyTrend builds a data-anchored 7-day window, zero-filled', () {
    final fixed = DateTime(2026, 7, 15);
    final cubit = buildCubit(now: () => fixed);
    ordersCtrl.add([
      order(1, OrderStatus.pending, 1000, createdAt: DateTime(2026, 7, 10, 9)),
      // Cancelled: contributes neither revenue nor count (the status chart
      // shows cancellations separately).
      order(2, OrderStatus.cancelled, 9999, createdAt: DateTime(2026, 7, 11, 9)),
      order(3, OrderStatus.delivered, 2500, createdAt: DateTime(2026, 7, 13, 9)),
    ]);
    productsCtrl.add(const []);
    couponsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    // The window is data-anchored: it ends at the latest order day (July
    // 13), NOT the injected clock (July 15) — the chart never depends on
    // the wall clock while orders exist.
    expect(loaded.dailyTrend, hasLength(AdminOverviewLoaded.trendDays));
    expect(loaded.dailyTrend.first.day, DateTime(2026, 7, 7));
    expect(loaded.dailyTrend.last.day, DateTime(2026, 7, 13));
    // Zero-filled middle day (July 8): no sales.
    expect(loaded.dailyTrend[1].revenueCents, 0);
    expect(loaded.dailyTrend[1].orderCount, 0);
    // July 10: one pending order → 1000 / 1.
    final day10 =
        loaded.dailyTrend.singleWhere((d) => d.day == DateTime(2026, 7, 10));
    expect(day10.revenueCents, 1000);
    expect(day10.orderCount, 1);
    // July 11: cancelled → the day exists in the window but reads zero.
    final day11 =
        loaded.dailyTrend.singleWhere((d) => d.day == DateTime(2026, 7, 11));
    expect(day11.revenueCents, 0);
    expect(day11.orderCount, 0);
    // July 13: 2500 / 1.
    final day13 =
        loaded.dailyTrend.singleWhere((d) => d.day == DateTime(2026, 7, 13));
    expect(day13.revenueCents, 2500);
    expect(day13.orderCount, 1);

    cubit.close();
  });

  test('dailyTrend ignores cancelled orders when anchoring the window', () {
    final fixed = DateTime(2026, 7, 15);
    final cubit = buildCubit(now: () => fixed);
    ordersCtrl.add([
      order(1, OrderStatus.pending, 1000, createdAt: DateTime(2026, 7, 10, 9)),
      // Cancelled AFTER the latest sale: it must neither anchor the window
      // (which would push the last bar to a non-sale zero day) nor count.
      order(2, OrderStatus.cancelled, 9999, createdAt: DateTime(2026, 7, 14, 9)),
    ]);
    productsCtrl.add(const []);
    couponsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    // Window ends at July 10 (the latest non-cancelled day), not July 14.
    expect(loaded.dailyTrend.last.day, DateTime(2026, 7, 10));
    expect(loaded.dailyTrend.first.day, DateTime(2026, 7, 4));
    // The cancelled order's day isn't even inside the window.
    expect(
      loaded.dailyTrend.any((d) => d.day == DateTime(2026, 7, 14)),
      isFalse,
    );

    cubit.close();
  });

  test('dailyTrend falls back to the injected clock when no orders exist',
      () {
    final fixed = DateTime(2026, 7, 15);
    final cubit = buildCubit(now: () => fixed);
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    couponsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    expect(loaded.dailyTrend, hasLength(AdminOverviewLoaded.trendDays));
    expect(loaded.dailyTrend.last.day, DateTime(2026, 7, 15));
    expect(loaded.dailyTrend.first.day, DateTime(2026, 7, 9));
    expect(
      loaded.dailyTrend.every(
        (d) => d.revenueCents == 0 && d.orderCount == 0,
      ),
      isTrue,
    );

    cubit.close();
  });

  test('topProducts aggregates non-cancelled line snapshots, by revenue then '
      'units', () {
    final cubit = buildCubit();
    ordersCtrl.add([
      order(1, OrderStatus.pending, 1000, items: [
        OrderItem(orderId: 1, productName: 'Tee', unitPriceCents: 1000, quantity: 2),
        OrderItem(orderId: 1, productName: 'Mug', unitPriceCents: 500, quantity: 1),
      ]),
      order(2, OrderStatus.delivered, 1000, items: [
        OrderItem(orderId: 2, productName: 'Tee', unitPriceCents: 1000, quantity: 1),
      ]),
      // Cancelled: its (huge) lines never rank.
      order(3, OrderStatus.cancelled, 1000, items: [
        OrderItem(orderId: 3, productName: 'Giant', unitPriceCents: 9000, quantity: 99),
      ]),
    ]);
    productsCtrl.add(const []);
    couponsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    // Tee: 3 units × $10 = $30 revenue; Mug: 1 × $5 = $5. Revenue desc.
    expect(loaded.topProducts.map((p) => p.name), ['Tee', 'Mug']);
    expect(loaded.topProducts.first.unitsSold, 3);
    expect(loaded.topProducts.first.revenueCents, 3000);
    expect(loaded.topProducts.last.unitsSold, 1);
    expect(loaded.topProducts.last.revenueCents, 500);
    expect(
      loaded.topProducts.any((p) => p.name == 'Giant'),
      isFalse,
      reason: 'cancelled orders never contribute to the ranking',
    );

    cubit.close();
  });

  test('topProducts carries the Arabic snapshot label and caps at the limit',
      () {
    final cubit = buildCubit();
    ordersCtrl.add([
      order(1, OrderStatus.pending, 1000, items: [
        // Tee outsells every other product (2 × $10 = $20 revenue), so it
        // ranks FIRST — proving the Arabic label rides along.
        OrderItem(
          orderId: 1,
          productName: 'Tee',
          productNameAr: 'تيشيرت',
          unitPriceCents: 1000,
          quantity: 2,
        ),
        OrderItem(
          orderId: 1,
          productName: 'Mug',
          unitPriceCents: 1000,
          quantity: 1,
        ),
      ]),
      for (var i = 2; i <= 5; i++)
        order(i, OrderStatus.pending, 1000, items: [
          OrderItem(
            orderId: i,
            productName: 'Product $i',
            unitPriceCents: 1000,
            quantity: 1,
          ),
        ]),
    ]);
    productsCtrl.add(const []);
    couponsCtrl.add(const []);

    final loaded = cubit.state as AdminOverviewLoaded;
    // 6 products total → capped at 5. Tee (2000) ranks first; the five
    // $10-revenue products tie on revenue and units, so name asc fills the
    // rest — 'Mug', 'Product 2'..'Product 4' — and 'Product 5' drops.
    expect(loaded.topProducts, hasLength(AdminOverviewLoaded.topProductsLimit));
    expect(loaded.topProducts.first.name, 'Tee');
    expect(loaded.topProducts.first.nameAr, 'تيشيرت');
    expect(loaded.topProducts.first.unitsSold, 2);
    expect(
      loaded.topProducts.any((p) => p.name == 'Product 5'),
      isFalse,
      reason: 'the limit drops the last name-asc tie',
    );
    expect(
      loaded.topProducts.any((p) => p.name == 'Mug' && p.nameAr == null),
      isTrue,
      reason: 'a product without an Arabic snapshot keeps nameAr null',
    );

    cubit.close();
  });

  test('a stream error becomes AdminOverviewError and is sticky', () {
    final cubit = buildCubit();
    ordersCtrl.add(const []);
    productsCtrl.add(const []);
    couponsCtrl.add(const []);
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
    expect(couponsCtrl.hasListener, isFalse);
  });
}

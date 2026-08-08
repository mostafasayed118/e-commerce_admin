import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/features/admin/orders/admin_order_detail_screen.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/stat_card.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/top_coupon_tile.dart';

import '../helpers/admin_flow.dart';
import '../helpers/drift_settle.dart';
import '../helpers/shop_flow.dart';
import '../helpers/test_di.dart';

/// End-to-end admin overview: real DI graph (memory DB + seed) + router.
/// The gate lands on the overview after unlocking; asserts the derived
/// metrics against the known seed values, the chart's presence, and the
/// dashboard's cross-links (recent order → order detail, low stock → product
/// edit).
void main() {
  late AppDatabase db;
  late GoRouter router;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    router.dispose();
    await db.close();
    await getIt.reset();
  });

  testWidgets('overview shows derived metrics and the chart', (
      WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 2200));
    await unlockAdmin(tester, router: router);
    await settleDrift(tester); // overview cubit streams
    await tester.pumpAndSettle();

    // Seed-derived metrics (revenue excludes the cancelled order):
    // 5220 + 7574 + 16000 + 5400 + 6600 = 40794 → $407.94.
    expect(find.text(r'$407.94'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // orders card
    expect(find.text('5'), findsOneWidget); // low-stock card

    // The fl_chart bar chart renders with all five status labels.
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Cancelled'), findsWidgets);

    // Recent orders: the newest seed order tops the list.
    expect(find.text('ORD-000004'), findsOneWidget);

    // Coupons: the active-coupons card, the top-coupons ranking (SAVE5 tops
    // the seed with 3 of 5 capped uses, WELCOME10 with 2 uncapped) and the
    // recent-usage rows (four seed orders carry coupon snapshots — SAVE5 and
    // WELCOME10 each appear in two usage rows plus one ranking row). The
    // exact active count is date-dependent, so it is pinned by the cubit
    // unit tests with an injected clock. SectionHeader renders its labels in
    // ALL CAPS.
    expect(find.text('Active coupons'), findsOneWidget);
    expect(find.text('TOP COUPONS'), findsOneWidget);
    expect(find.text('60% used'), findsOneWidget); // SAVE5 ranking row (capped)
    expect(find.text('2 uses'), findsOneWidget); // WELCOME10 ranking row
    // Ranking order: the tiles render in state.topCoupons order — the capped
    // SAVE5 (3 of 5 = 60% of its cap) ranks above the uncapped WELCOME10
    // (2 uses), because capped coupons are ranked by exhaustion % first and
    // unlimited ones by count after (the discriminating order is pinned by
    // the cubit unit tests).
    final rankingCodes = tester
        .widgetList<TopCouponTile>(find.byType(TopCouponTile))
        .map((t) => t.ranking.code);
    expect(rankingCodes, ['SAVE5', 'WELCOME10']);

    expect(find.text('COUPON USAGE'), findsOneWidget);
    expect(find.text('WELCOME10'), findsWidgets);
    expect(find.text('SAVE5'), findsWidgets);
    expect(find.text('No coupon usage yet.'), findsNothing);
    expect(find.text('No coupons used yet.'), findsNothing);

    // Low-stock alerts: out-of-stock and low-stock products, sorted.
    expect(find.text('Out of stock'), findsWidgets); // Leather Belt, Yoga Mat
    expect(find.text('Only 3 left'), findsOneWidget); // Clean Architecture

    await unmountApp(tester);
  });

  testWidgets('Arabic: the stat-card counts render Eastern digits',
      (WidgetTester tester) async {
    router = await pumpRouterApp(
      tester,
      size: const Size(900, 2200),
      locale: const Locale('ar'),
    );
    await unlockAdmin(tester, router: router, setPinLabel: 'تعيين الرمز');
    await settleDrift(tester); // overview cubit streams
    await tester.pumpAndSettle();

    // The raw counts convert like prices/dates: orders 6 → ٦, low stock
    // 5 → ٥. Scoped to StatCard so the digit-only finders can't collide
    // with other dashboard text. (Revenue was already Eastern via
    // formatCents.)
    Finder inStatCards(String text) => find.descendant(
          of: find.byType(StatCard),
          matching: find.text(text),
        );
    expect(inStatCards('٦'), findsOneWidget); // orders card
    expect(inStatCards('٥'), findsOneWidget); // low-stock card
    // The English digits are gone.
    expect(inStatCards('6'), findsNothing);
    expect(inStatCards('5'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('dashboard links reach the order detail, product edit, and '
      'coupons tab', (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 2200));
    await unlockAdmin(tester, router: router);
    await settleDrift(tester);
    await tester.pumpAndSettle();

    // Recent order → admin order detail.
    await tester.tap(find.text('ORD-000004'));
    await settleAction(tester);
    expect(find.byType(AdminOrderDetailScreen), findsOneWidget);
    expect(find.text('Mark confirmed'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    // Low-stock product → product edit form.
    await tester.tap(find.text('Yoga Mat'));
    await settleAction(tester);
    expect(find.text('Edit product'), findsOneWidget);
    expect(find.text('Save product'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    // Top-coupons ranking → the Coupons tab (a shell-branch switch via `go`,
    // not a pushed route). 'SAVE5' is unique to the ranking row in the
    // TopCouponTile finder (the usage rows are a different widget type).
    final topTile = find.widgetWithText(TopCouponTile, 'SAVE5');
    expect(topTile, findsOneWidget);
    await tester.tap(topTile);
    await settleAction(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/admin/coupons',
    );
    // The coupons list rendered (the dashboard's copies of 'SAVE5' are
    // offstage in the kept-alive shell branch, so the row is unique now).
    expect(find.text('EXPIRED10'), findsOneWidget);

    await unmountApp(tester);
  });
}

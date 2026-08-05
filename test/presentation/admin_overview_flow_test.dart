import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/presentation/features/admin/orders/admin_order_detail_screen.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

import '../helpers/drift_settle.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = buildAppRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  /// Sets the PIN on the gate; it navigates to /admin/overview on success.
  Future<void> unlockAdmin(WidgetTester tester) async {
    router.go('/admin/gate');
    await tester.pump();
    await settleDrift(tester); // isPinSet query
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Set PIN'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/admin/overview',
    );
  }

  testWidgets('overview shows derived metrics and the chart', (
      WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester);
    await settleDrift(tester); // overview cubit streams
    await tester.pumpAndSettle();

    // Seed-derived metrics (revenue excludes the cancelled order):
    // 5800 + 8415 + 16500 + 5900 + 7100 = 43715 → $437.15.
    expect(find.text(r'$437.15'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // orders card
    expect(find.text('5'), findsOneWidget); // low-stock card

    // The fl_chart bar chart renders with all five status labels.
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Cancelled'), findsWidgets);

    // Recent orders: the newest seed order tops the list.
    expect(find.text('ORD-000004'), findsOneWidget);

    // Low-stock alerts: out-of-stock and low-stock products, sorted.
    expect(find.text('Out of stock'), findsWidgets); // Leather Belt, Yoga Mat
    expect(find.text('Only 3 left'), findsOneWidget); // Clean Architecture

    await unmountApp(tester);
  });

  testWidgets('dashboard links reach the order detail and product edit',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester);
    await settleDrift(tester);
    await tester.pumpAndSettle();

    // Recent order → admin order detail.
    await tester.tap(find.text('ORD-000004'));
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AdminOrderDetailScreen), findsOneWidget);
    expect(find.text('Mark confirmed'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    // Low-stock product → product edit form.
    await tester.tap(find.text('Yoga Mat'));
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();
    expect(find.text('Edit product'), findsOneWidget);
    expect(find.text('Save product'), findsOneWidget);

    await unmountApp(tester);
  });
}

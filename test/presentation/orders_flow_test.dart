import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// End-to-end order history: real DI graph + router. The seed provides six
/// demo orders with full status histories (spec A6), so the list and the
/// detail timeline are demoable immediately.
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

  Future<void> pumpApp(WidgetTester tester, {bool seed = true}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (seed) {
      await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    }
    router = buildAppRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  Future<void> goToOrders(WidgetTester tester) async {
    router.go('/orders');
    await tester.pump();
    await settleDrift(tester); // OrdersCubit watch stream
    await tester.pumpAndSettle();
  }

  testWidgets('order history lists seeded orders newest first', (
      WidgetTester tester) async {
    await pumpApp(tester);
    await goToOrders(tester);

    // Newest first: ORD-000004 was placed 3 hours ago, before ORD-000003.
    final firstTile = tester.widget<ListTile>(find.byType(ListTile).first);
    expect((firstTile.title as Text).data, 'ORD-000004');

    // Status chips render across the list (delivered + pending both present).
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('Cancelled'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('order detail shows snapshot items and the status timeline',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToOrders(tester);

    // ORD-000001: delivered, 4-step history, 2 snapshot items.
    await tester.tap(find.text('ORD-000001'));
    await tester.pump();
    await settleDrift(tester); // detail screen's watchOrderById stream
    await tester.pumpAndSettle();

    expect(find.text('ORD-000001'), findsOneWidget);
    expect(find.text('Amira Hassan'), findsOneWidget); // shipping snapshot

    // Snapshot items (they survive product edits/deletions — Decision E).
    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text('Leather Belt'), findsOneWidget);
    // Savings row only shows when the order actually had discounts.
    expect(find.text('Savings'), findsOneWidget);

    // The full timeline: pending → confirmed → shipped → delivered.
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Shipped'), findsOneWidget);
    expect(find.text('Delivered'), findsWidgets); // chip + latest entry

    await unmountApp(tester);
  });

  testWidgets('a fresh install shows the empty order state', (
      WidgetTester tester) async {
    await pumpApp(tester, seed: false);
    await goToOrders(tester);

    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Browse products'), findsOneWidget);

    await unmountApp(tester);
  });
}

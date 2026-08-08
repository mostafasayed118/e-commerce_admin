import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';

import '../helpers/drift_settle.dart';
import '../helpers/nav.dart';
import '../helpers/shop_flow.dart';
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

  testWidgets('order history lists seeded orders newest first', (
      WidgetTester tester) async {
    router = await pumpRouterApp(tester);
    await goToDestination(tester, router, '/orders');

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
    router = await pumpRouterApp(tester);
    await goToDestination(tester, router, '/orders');

    // ORD-000001: delivered, 4-step history, 2 snapshot items.
    await tester.tap(find.text('ORD-000001'));
    await settleAction(tester); // detail screen's watchOrderById stream

    expect(find.text('ORD-000001'), findsOneWidget);
    expect(find.text('Amira Hassan'), findsOneWidget); // shipping snapshot

    // The receipt-export action is present (enabled — the order is loaded).
    // It is not tapped: the native save dialog is a platform boundary
    // outside widget tests; the serialization is unit-tested in
    // order_receipt_pdf_test.
    expect(find.byTooltip('Download receipt'), findsOneWidget);
    final downloadButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(downloadButton.onPressed, isNotNull);

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
    router = await pumpRouterApp(tester, seed: false);
    await goToDestination(tester, router, '/orders');

    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Browse products'), findsOneWidget);

    await unmountApp(tester);
  });
}

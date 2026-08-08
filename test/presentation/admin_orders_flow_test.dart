import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/data/database/app_database.dart';

import '../helpers/admin_flow.dart';
import '../helpers/drift_settle.dart';
import '../helpers/nav.dart';
import '../helpers/shop_flow.dart';
import '../helpers/storefront_exit.dart';
import '../helpers/test_di.dart';

/// End-to-end admin order management: real DI graph (memory DB + seed) +
/// router. Unlocks through the PIN gate, filters the order list, then moves a
/// pending order through the state machine from the detail screen — proving
/// the UI offers exactly the legal transitions and the timeline/chip refresh
/// live.
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

  testWidgets('admin filters orders and moves a pending order to confirmed',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 1600));
    await unlockAdmin(tester, router: router);
    await goToDestination(tester, router, '/admin/orders');

    // All six seeded orders are listed.
    expect(find.text('ORD-000001'), findsOneWidget);
    expect(find.text('ORD-000006'), findsOneWidget);

    // The CSV export action is present (enabled — orders are visible). It is
    // not tapped here: the native save dialog is a platform boundary outside
    // widget tests; the serialization is unit-tested in order_csv_test.
    expect(find.byTooltip('Export orders'), findsOneWidget);
    final exportButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(exportButton.onPressed, isNotNull);

    // --- Filter by Pending: only ORD-000004 remains -----------------------
    // Target the ChoiceChip, not the status chip on the ORD-000004 tile.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
    await tester.pumpAndSettle();
    expect(find.text('ORD-000004'), findsOneWidget);
    expect(find.text('ORD-000001'), findsNothing);

    // --- Open the pending order and advance it ------------------------------
    await tester.tap(find.text('ORD-000004'));
    await settleAction(tester); // detail watchOrderById stream

    // The pushed admin detail carries its own storefront exit.
    expectStorefrontAction(reason: 'admin order detail');

    // A pending order offers exactly: confirm (forward) + cancel.
    expect(find.text('Mark confirmed'), findsOneWidget);
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Mark shipped'), findsNothing); // not yet legal

    await tester.tap(find.text('Mark confirmed'));
    await settleAdminWrite(tester);

    // Success feedback + the live-refreshed detail: chip, timeline, buttons.
    expect(find.text('ORD-000004 marked as Confirmed'), findsOneWidget);
    expect(find.text('Confirmed'), findsWidgets); // chip + timeline entry
    expect(find.text('Pending'), findsOneWidget); // older timeline entry
    expect(find.text('Mark shipped'), findsOneWidget); // now legal
    expect(find.text('Mark confirmed'), findsNothing); // no longer legal

    // DB proof: the status row and a second history entry were written.
    final orderRow =
        await (db.select(db.orders)..where((t) => t.id.equals(4)))
            .getSingle();
    expect(orderRow.status, OrderStatus.confirmed); // drift intEnum maps back
    final historyRows = await (db.select(db.orderStatusHistory)
          ..where((t) => t.orderId.equals(4)))
        .get();
    expect(historyRows, hasLength(2));

    await settleSnackBar(tester);
    await unmountApp(tester);
  });

  testWidgets('search and date filters narrow the order list and clear',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 1600));
    await unlockAdmin(tester, router: router);
    await goToDestination(tester, router, '/admin/orders');

    expect(find.text('ORD-000001'), findsOneWidget);

    // --- Search by order number, hyphen-insensitive ------------------------
    await tester.enterText(find.byType(TextField), 'ord-4');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ORD-000004'), findsOneWidget);
    expect(find.text('ORD-000001'), findsNothing);

    // The field's one-tap clear restores the list.
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ORD-000001'), findsOneWidget);

    // --- Date range: From = today (seed orders are July 2026) --------------
    await tester.tap(find.widgetWithText(ActionChip, 'From'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Every seeded order predates today, so the range leaves nothing; the
    // adapted empty state offers Clear filters, which restores everything.
    expect(find.text('No matching orders'), findsOneWidget);

    // With nothing visible, the export action disables (the BlocBuilder
    // gate in action).
    final disabledExport = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(disabledExport.onPressed, isNull);

    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ORD-000001'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('terminal orders offer no further actions',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 1600));
    await unlockAdmin(tester, router: router);
    await goToDestination(tester, router, '/admin/orders');

    // ORD-000001 is delivered (terminal).
    await tester.tap(find.text('ORD-000001'));
    await settleAction(tester);

    expect(
      find.textContaining('no further actions'),
      findsOneWidget,
    );
    expect(find.text('Mark confirmed'), findsNothing);
    expect(find.text('Cancel order'), findsNothing);

    await unmountApp(tester);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';
import '../helpers/test_app.dart';

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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = buildAppRouter();
    await tester.pumpWidget(testApp(router));
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

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

  Future<void> goToOrders(WidgetTester tester) async {
    router.go('/admin/orders');
    await tester.pump();
    await settleDrift(tester); // AdminOrdersCubit watch stream
    await tester.pumpAndSettle();
  }

  testWidgets('admin filters orders and moves a pending order to confirmed',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester);
    await goToOrders(tester);

    // All six seeded orders are listed.
    expect(find.text('ORD-000001'), findsOneWidget);
    expect(find.text('ORD-000006'), findsOneWidget);

    // --- Filter by Pending: only ORD-000004 remains -----------------------
    // Target the ChoiceChip, not the status chip on the ORD-000004 tile.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
    await tester.pumpAndSettle();
    expect(find.text('ORD-000004'), findsOneWidget);
    expect(find.text('ORD-000001'), findsNothing);

    // --- Open the pending order and advance it ------------------------------
    await tester.tap(find.text('ORD-000004'));
    await tester.pump();
    await settleDrift(tester); // detail watchOrderById stream
    await tester.pumpAndSettle();

    // A pending order offers exactly: confirm (forward) + cancel.
    expect(find.text('Mark confirmed'), findsOneWidget);
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Mark shipped'), findsNothing); // not yet legal

    await tester.tap(find.text('Mark confirmed'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

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

    // Flush the SnackBar timer before unmounting.
    await tester.pump(const Duration(seconds: 5));
    await unmountApp(tester);
  });

  testWidgets('terminal orders offer no further actions',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester);
    await goToOrders(tester);

    // ORD-000001 is delivered (terminal).
    await tester.tap(find.text('ORD-000001'));
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('no further actions'),
      findsOneWidget,
    );
    expect(find.text('Mark confirmed'), findsNothing);
    expect(find.text('Cancel order'), findsNothing);

    await unmountApp(tester);
  });
}

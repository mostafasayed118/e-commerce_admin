import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';

import '../helpers/admin_flow.dart';
import '../helpers/drift_settle.dart';
import '../helpers/nav.dart';
import '../helpers/shop_flow.dart';
import '../helpers/test_di.dart';

/// End-to-end admin review moderation: real DI graph (memory DB + seed) +
/// the real router. Drives the PIN gate, then exercises approve/hide and
/// delete through the actual screens.
///
/// Ordering rule throughout: `pump()` first, THEN `settleDrift` (drift's
/// background-isolate responses land only in the real zone), then
/// `pumpAndSettle` — never settle before the DB responds, or a spinner
/// animates forever and the settle hangs.
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

  testWidgets('admin moderates reviews: approve the pending one, delete one',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 1600));
    await unlockAdmin(tester, router: router, setPinTitle: 'Set an admin PIN');
    await goToDestination(tester, router, '/admin/reviews');

    // --- The seeded list: approved + the one pending review ---------------
    // Sara Nabil's 2-star review is the seed's hidden (pending) demo. She
    // also has an approved review on another product, so anchor on the
    // unique pending comment ('Runs small for me.') to find her pending row.
    final pendingTile =
        find.widgetWithText(ListTile, 'Runs small for me.');
    expect(pendingTile, findsOneWidget);
    expect(
      find.descendant(of: pendingTile, matching: find.text('Pending')),
      findsOneWidget,
    );
    // Approved reviews show the Approved chip instead.
    final approvedTile = find.widgetWithText(ListTile, 'Amira Hassan');
    expect(
      find.descendant(of: approvedTile, matching: find.text('Approved')),
      findsOneWidget,
    );

    // --- Approve the pending review ---------------------------------------
    await tester.tap(
      find.descendant(of: pendingTile, matching: find.text('Approve')),
    );
    await settleAdminWrite(tester);
    // The watch stream re-emits: Sara Nabil's row now wears Approved.
    expect(
      find.descendant(of: pendingTile, matching: find.text('Pending')),
      findsNothing,
    );
    expect(
      find.descendant(of: pendingTile, matching: find.text('Approved')),
      findsOneWidget,
    );

    // --- Hide it again (the toggle) ----------------------------------------
    await tester.tap(
      find.descendant(of: pendingTile, matching: find.text('Hide')),
    );
    await settleAdminWrite(tester);
    expect(
      find.descendant(of: pendingTile, matching: find.text('Pending')),
      findsOneWidget,
    );

    // --- Delete with the confirm dialog ------------------------------------
    await tester.tap(find.descendant(
      // Karim Adel has two approved reviews (tee + Flutter book) — the
      // delete targets the first tile, then its absence is asserted on the
      // remaining row count rather than the name.
      of: find.widgetWithText(ListTile, 'Karim Adel').first,
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Delete review?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await settleAdminWrite(tester);
    expect(find.widgetWithText(ListTile, 'Karim Adel'), findsOneWidget,
        reason: 'one of his two reviews remains');

    await unmountApp(tester);
  });
}

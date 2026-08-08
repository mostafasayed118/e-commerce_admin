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

/// End-to-end admin coupons: real DI graph (memory DB + seed) + the real
/// router. Drives the PIN gate, then exercises coupon CRUD through the
/// actual screens and form.
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

  testWidgets('admin manages coupons: list, create, duplicate, edit, delete',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 1600));
    await unlockAdmin(tester, router: router, setPinTitle: 'Set an admin PIN');
    await goToDestination(tester, router, '/admin/coupons');

    // --- The seeded list: codes, types, and the expired chip ---------------
    for (final code in ['WELCOME10', 'SAVE5', 'SUMMER20', 'EXPIRED10']) {
      expect(find.text(code), findsOneWidget);
    }
    expect(find.text('10% off · min \$30.00 · Unlimited'), findsOneWidget);
    // SAVE5 carries the demo usage cap → its subtitle shows used/max.
    expect(find.text(r'$5.00 off · 3/5 uses'), findsOneWidget);
    // The expired demo coupon wears its status chip (deterministic: the seed
    // pins EXPIRED10's expiry in the past).
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'EXPIRED10'),
        matching: find.text('Expired'),
      ),
      findsOneWidget,
    );

    // --- Create ------------------------------------------------------------
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('New coupon'), findsWidgets); // FAB label + AppBar

    // Validation contract: an empty form cannot be saved.
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('coupon-code')), 'flash25');
    await tester.enterText(find.byKey(const Key('coupon-value')), '25');

    // The optional min-spend field validates money input — garbage is caught
    // by the validator (never a crash from the parser's `!`).
    await tester.enterText(
      find.byKey(const Key('coupon-min-spend')),
      '12.345',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a price greater than 0'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('coupon-min-spend')), '');

    await tester.tap(find.text('Save'));
    await settleAdminWrite(tester);

    // Back on the list: the code was normalized and the discount shows.
    expect(find.text('FLASH25'), findsOneWidget);
    expect(find.text('25% off · Unlimited'), findsOneWidget);

    // --- Duplicate code is rejected with the localized error ---------------
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('coupon-code')), 'save5');
    await tester.enterText(find.byKey(const Key('coupon-value')), '10');
    await tester.tap(find.text('Save'));
    await settleAdminWrite(tester);
    expect(find.text('That code is already in use.'), findsOneWidget);
    expect(find.byKey(const Key('coupon-code')), findsOneWidget,
        reason: 'the failed save keeps the form open');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // --- Edit (tap the row) -------------------------------------------------
    await tester.tap(find.text('WELCOME10'));
    await tester.pumpAndSettle();
    expect(find.text('Edit coupon'), findsOneWidget);
    // The percent value prefills from cents.
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('coupon-value')))
          .controller!
          .text,
      '10',
    );
    await tester.enterText(find.byKey(const Key('coupon-value')), '15');
    await tester.tap(find.text('Save'));
    await settleAdminWrite(tester);
    expect(find.text('15% off · min \$30.00 · Unlimited'), findsOneWidget);

    // --- Delete (confirm dialog) --------------------------------------------
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'SAVE5'),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Delete coupon?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await settleAdminWrite(tester);
    expect(find.text('SAVE5'), findsNothing);

    await unmountApp(tester);
  });
}

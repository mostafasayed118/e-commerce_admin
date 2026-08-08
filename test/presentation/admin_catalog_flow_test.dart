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

/// End-to-end admin catalog: real DI graph (memory DB + seed) + the real
/// router. Drives the PIN gate, unlocks, then exercises product and category
/// CRUD through the actual screens and forms.
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

  testWidgets('admin sets a PIN, unlocks, and manages products end-to-end',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 1600));
    await unlockAdmin(tester, router: router, setPinTitle: 'Set an admin PIN');

    await goToDestination(tester, router, '/admin/products');
    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text('Out of stock'), findsWidgets); // seed has some

    // --- Create ------------------------------------------------------------
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Save product'), findsOneWidget);

    // Validation contract: an empty form cannot be saved (name + price both
    // show their field-level errors, nothing reaches the repository).
    await tester.tap(find.text('Save product'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Enter a price greater than 0'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('product-name')), 'Test Product');
    await tester.enterText(
        find.byKey(const Key('product-name-ar')), 'قميص تجريبي');
    await tester.enterText(find.byKey(const Key('product-price')), '19.99');
    await tester.tap(find.text('Save product'));
    await settleAdminWrite(tester);

    expect(find.text('Test Product'), findsOneWidget);

    // --- Edit (tap the row) ------------------------------------------------
    await tester.tap(find.text('Test Product'));
    await tester.pumpAndSettle();
    expect(find.text('Edit product'), findsOneWidget);
    expect(find.text('19.99'), findsOneWidget); // price prefilled from cents
    // The optional Arabic name persisted through form -> DB -> form.
    expect(find.text('قميص تجريبي'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('product-name')),
      'Test Product V2',
    );
    await tester.tap(find.text('Save product'));
    await settleAdminWrite(tester);

    expect(find.text('Test Product V2'), findsOneWidget);

    // --- Delete (confirm dialog) -------------------------------------------
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Test Product V2'),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Delete product?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await settleAdminWrite(tester);

    expect(find.text('Test Product V2'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('admin manages categories: add, blocked delete, empty delete',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(900, 1600));
    await unlockAdmin(tester, router: router, setPinTitle: 'Set an admin PIN');

    await goToDestination(tester, router, '/admin/categories');
    expect(find.text('Clothing'), findsOneWidget);

    // --- Add ---------------------------------------------------------------
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Gadgets',
    );
    await tester.enterText(
      find.byKey(const Key('category-name-ar-field')),
      'أجهزة',
    );
    await tester.tap(find.text('Create'));
    await settleAdminWrite(tester);
    expect(find.text('Gadgets'), findsOneWidget);

    // The optional Arabic label persisted: the rename dialog pre-fills it.
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Gadgets'),
      matching: find.byIcon(Icons.edit_outlined),
    ));
    await tester.pumpAndSettle();
    expect(find.text('أجهزة'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // --- Blocked delete: 'Clothing' still has products (spec A4) -----------
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Clothing'),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settleAdminWrite(tester);
    expect(find.textContaining('before deleting the category'), findsOneWidget);
    expect(find.text('Clothing'), findsOneWidget); // still there

    await settleSnackBar(tester);

    // --- Empty delete succeeds ---------------------------------------------
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Gadgets'),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settleAdminWrite(tester);
    expect(find.text('Gadgets'), findsNothing);

    await unmountApp(tester);
  });
}

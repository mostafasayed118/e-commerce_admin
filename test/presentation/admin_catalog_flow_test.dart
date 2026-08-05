import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

import '../helpers/drift_settle.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
    // Wide + tall: NavigationRail layout, and every list tile visible without
    // scrolling (so finders stay simple and deterministic).
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = buildAppRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  Future<String> currentPath(WidgetTester tester) async {
    await settleDrift(tester);
    await tester.pumpAndSettle();
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  /// Fresh DB has no PIN → the gate shows the set-PIN form; set one and land
  /// on the admin overview (the guard now lets /admin/* through).
  Future<void> unlockAdmin(WidgetTester tester) async {
    router.go('/admin/gate');
    await tester.pump();
    await settleDrift(tester); // isPinSet query
    await tester.pumpAndSettle();

    expect(find.text('Set an admin PIN'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Set PIN'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(await currentPath(tester), '/admin/overview');
  }

  Future<void> goToProducts(WidgetTester tester) async {
    router.go('/admin/products');
    await tester.pump();
    await settleDrift(tester); // AdminCatalogCubit watch streams
    await tester.pumpAndSettle();
  }

  testWidgets('admin sets a PIN, unlocks, and manages products end-to-end',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester);

    await goToProducts(tester);
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
    await tester.enterText(find.byKey(const Key('product-price')), '19.99');
    await tester.tap(find.text('Save product'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Test Product'), findsOneWidget);

    // --- Edit (tap the row) ------------------------------------------------
    await tester.tap(find.text('Test Product'));
    await tester.pumpAndSettle();
    expect(find.text('Edit product'), findsOneWidget);
    expect(find.text('19.99'), findsOneWidget); // price prefilled from cents
    await tester.enterText(
      find.byKey(const Key('product-name')),
      'Test Product V2',
    );
    await tester.tap(find.text('Save product'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Test Product V2'), findsOneWidget);

    // --- Delete (confirm dialog) -------------------------------------------
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Test Product V2'),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Delete product?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Test Product V2'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('admin manages categories: add, blocked delete, empty delete',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester);

    router.go('/admin/categories');
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();
    expect(find.text('Clothing'), findsOneWidget);

    // --- Add ---------------------------------------------------------------
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Gadgets',
    );
    await tester.tap(find.text('Create'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Gadgets'), findsOneWidget);

    // --- Blocked delete: 'Clothing' still has products (spec A4) -----------
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Clothing'),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.textContaining('delete them first'), findsOneWidget);
    expect(find.text('Clothing'), findsOneWidget); // still there

    // Flush the SnackBar's auto-dismiss timer before interacting again.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // --- Empty delete succeeds ---------------------------------------------
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Gadgets'),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Gadgets'), findsNothing);

    await unmountApp(tester);
  });
}

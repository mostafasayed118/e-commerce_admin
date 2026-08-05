import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/presentation/app.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// End-to-end: the real DI graph (memory DB + seed) drives the real catalog
/// screen, product detail, and Add to Cart — the full stack in one test.
///
/// All database work (seeding, drift stream delivery, the AddToCart write)
/// runs inside `tester.runAsync`/`settleDrift`: testWidgets' FakeAsync zone
/// cannot see drift's background-isolate responses (see drift_settle.dart).
void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    await tester.pumpWidget(const ShopAdminApp());
    await settleDrift(tester); // deliver the catalog's initial watch emissions
    await tester.pumpAndSettle();
  }

  testWidgets('catalog shows seeded products and opens the detail screen',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Classic Tee'), findsOneWidget);
    // Discounted product shows its discount badge from the seed.
    expect(find.text('-25%'), findsOneWidget);

    await tester.tap(find.text('Classic Tee'));
    await tester.pump();
    await settleDrift(tester); // detail screen's watchProductById stream
    await tester.pumpAndSettle();

    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);

    // Back to the catalog, then scroll the lazy grid to an off-screen
    // product ('Wireless Earbuds' sorts later alphabetically).
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Wireless Earbuds'),
      200,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Wireless Earbuds'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('Add to Cart adds the product through the use case',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Classic Tee'));
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));

    expect(find.text('Classic Tee added to cart'), findsOneWidget);

    // The cart really persisted: one row for Classic Tee.
    final cartRows = await (db.select(db.cartItems)).get();
    expect(cartRows, hasLength(1));
    expect(cartRows.single.quantity, 1);

    // Flush the SnackBar's 4s auto-dismiss timer before unmounting.
    await tester.pump(const Duration(seconds: 5));
    await unmountApp(tester);
  });

  testWidgets('search filters the catalog in real time',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'yoga');
    // NOTE: pumpAndSettle would never settle here — the focused TextField's
    // cursor blinks, scheduling frames forever. Timed pumps only.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Yoga Mat'), findsOneWidget);
    expect(find.text('Classic Tee'), findsNothing);

    await unmountApp(tester);
  });
}

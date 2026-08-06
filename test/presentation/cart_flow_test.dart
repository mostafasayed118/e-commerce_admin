import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';
import '../helpers/test_app.dart';

/// End-to-end cart + checkout: real DI graph (memory DB + seed) + the real
/// router. Adds Classic Tee (25% off: $20.00 → $15.00) from the catalog,
/// then exercises the cart (badge, steppers, live totals, remove) and the
/// full checkout (validation, place order, cleared cart, persisted order).
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
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = buildAppRouter();
    await tester.pumpWidget(testApp(router));
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  /// Adds Classic Tee (qty 1) through the detail screen, then returns to the
  /// catalog. Assumes the catalog is the current screen.
  Future<void> addClassicTee(WidgetTester tester) async {
    await tester.tap(find.text('Classic Tee'));
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    // Flush the "added to cart" SnackBar: it floats over the bottom of the
    // screen and would otherwise swallow taps on the cart's Checkout button.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Future<void> goToCart(WidgetTester tester) async {
    await tester.tap(find.text('Cart'));
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('cart shows added items with live totals, steppers and badge',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await addClassicTee(tester);

    // The shell's Cart destination carries the count badge.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );

    await goToCart(tester);

    expect(find.text('Classic Tee'), findsOneWidget);
    // qty 1: savings -$5.00 (unique to the totals bar); the line total and
    // the bar total are both $15.00 (25% off the $20.00 unit price).
    expect(find.text(r'-$5.00'), findsOneWidget);
    expect(find.text(r'$15.00'), findsWidgets);

    // --- Step up to 2: totals recompute live --------------------------------
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text(r'$40.00'), findsOneWidget); // subtotal 2 × $20.00
    expect(find.text(r'-$10.00'), findsOneWidget); // savings 2 × $5.00
    expect(find.text(r'$30.00'), findsWidgets); // line + bar totals
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );

    // --- Step down back to 1 ------------------------------------------------
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // --- Remove the line: stepping down at qty 1 deletes it → empty state ---
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5)); // flush snackbar timers
    await unmountApp(tester);
  });

  testWidgets('checkout validates, places the order, and clears the cart',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await addClassicTee(tester);
    await goToCart(tester);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    // Empty form is blocked with the same messages the domain validates.
    await tester.tap(find.text('Place order — Cash on delivery'));
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    expect(find.text('Address is required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('checkout-name')), 'Test User');
    await tester.enterText(
      find.byKey(const Key('checkout-phone')),
      '0100 000 0000',
    );
    await tester.enterText(
      find.byKey(const Key('checkout-address')),
      '1 Test Street',
    );
    await tester.tap(find.text('Place order — Cash on delivery'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Success view with the generated order number.
    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.textContaining('ORD-'), findsOneWidget);

    // The order really persisted (6 seeded + 1) and the cart was cleared.
    final cartRows = await (db.select(db.cartItems)).get();
    expect(cartRows, isEmpty);
    final orderRows = await (db.select(db.orders)).get();
    expect(orderRows, hasLength(7));

    // The saved profile pre-fill data landed too.
    final profile = await getIt<SettingsRepository>().getProfile();
    expect(profile.getOrNull()?.name, 'Test User');

    await tester.tap(find.text('Back to shop'));
    await tester.pumpAndSettle();
    expect(find.text('Shop'), findsWidgets);
    // Cart is empty → no badge count on the shell.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 5)); // flush snackbar timers
    await unmountApp(tester);
  });
}

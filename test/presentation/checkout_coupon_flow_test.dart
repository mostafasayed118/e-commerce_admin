import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';

import '../helpers/drift_settle.dart';
import '../helpers/nav.dart';
import '../helpers/shop_flow.dart';
import '../helpers/test_di.dart';

/// End-to-end checkout with coupons: real DI graph (memory DB + seed) + the
/// real router. Adds Classic Tee (25% off: $20.00 → $15.00), then at checkout
/// exercises the coupon preview (invalid code, min spend, apply/remove) and a
/// placement that re-validates and snapshots the coupon on the order.
///
/// Ordering rule throughout: `pump()` first, THEN `settleDrift` (drift's
/// background-isolate responses land only in the real zone), then
/// `pumpAndSettle`.
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

  Future<void> goToCheckout(WidgetTester tester) async {
    await goToDestinationByLabel(tester, 'Cart');
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
  }

  /// The coupon entry TextField: the entry field is the only TextField whose
  /// subtree carries the outlined confirmation icon (the icon lives inside
  /// the field, so it's an ancestor-search).
  Finder couponField() => find.ancestor(
        of: find.byIcon(Icons.confirmation_number_outlined),
        matching: find.byType(TextField),
      );

  Future<void> applyCoupon(WidgetTester tester, String code) async {
    await tester.enterText(couponField(), code);
    await tester.tap(find.text('Apply'));
    await settleAction(tester, delay: const Duration(milliseconds: 200));
  }

  testWidgets('checkout previews coupons, rejects bad ones, and snapshots '
      'the applied code on the order', (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(420, 1600));
    await addClassicTee(tester);
    await goToCheckout(tester);

    // Classic Tee: $20.00 × 25% off = $15.00 eligible subtotal.
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(r'$20.00'), findsOneWidget);
    expect(find.text(r'-$5.00'), findsOneWidget); // line savings
    expect(find.text(r'$15.00'), findsOneWidget); // total before coupon

    // --- An unknown code is rejected inline --------------------------------
    await applyCoupon(tester, 'NOPE');
    expect(find.text('NOPE is not a valid code.'), findsOneWidget);

    // --- WELCOME10's $30.00 minimum spend is not met -------------------------
    await applyCoupon(tester, 'WELCOME10');
    expect(
      find.text(
        'Spend at least \$30.00 to use this code (your subtotal is \$15.00).',
      ),
      findsOneWidget,
    );

    // --- A valid fixed coupon applies (lowercase input is normalized) ------
    await applyCoupon(tester, 'save5');

    // Applied chip + the summary's coupon line + the new total.
    expect(find.text('SAVE5 · −\$5.00'), findsOneWidget);
    expect(find.text('Coupon (SAVE5)'), findsOneWidget);
    expect(find.text(r'-$5.00'), findsNWidgets(2)); // savings + coupon rows
    expect(find.text(r'$10.00'), findsOneWidget); // $15.00 - $5.00 total

    // --- Remove, then re-apply for the placement ----------------------------
    await tester.tap(find.byTooltip('Remove coupon'));
    await tester.pumpAndSettle();
    expect(couponField(), findsOneWidget, reason: 'the entry field returns');

    await applyCoupon(tester, 'SAVE5');
    expect(find.text('SAVE5 · −\$5.00'), findsOneWidget);

    // --- Fill shipping and place the order ----------------------------------
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
    await settleAction(tester, delay: const Duration(milliseconds: 300));

    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.textContaining('ORD-'), findsOneWidget);

    // The placed order carries the coupon snapshot (Decision E) and the
    // usage counter incremented atomically.
    final orders = await db.select(db.orders).get();
    final placed = orders.singleWhere((o) => o.orderNumber == 'ORD-000007');
    expect(placed.couponCode, 'SAVE5');
    expect(placed.couponDiscountCents, 500);
    expect(placed.totalCents, 1000); // 1500 - 500
    final coupon =
        await (db.select(db.coupons)..where((t) => t.code.equals('SAVE5')))
            .getSingle();
    expect(coupon.usedCount, 4,
        reason: 'the seed already used SAVE5 three times (ORD-000003, '
            'ORD-000004, ORD-000006)');

    await settleSnackBar(tester);
    await unmountApp(tester);
  });
}

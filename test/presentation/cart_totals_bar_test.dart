import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/cart/widgets/cart_totals_bar.dart';

/// Isolated tests for [CartTotalsBar]: formatted subtotal/savings/total rows
/// (integer-cents math, locale-driven sign placement) and the checkout action.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('shows the formatted rows and fires the checkout action',
      (WidgetTester tester) async {
    var checkedOut = false;
    await tester.pumpWidget(wrap(CartTotalsBar(
      subtotalCents: 1234,
      discountCents: 234,
      totalCents: 1000,
      onCheckout: () => checkedOut = true,
    )));

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(r'$12.34'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(r'$10.00'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    expect(checkedOut, isTrue);
  });

  testWidgets('renders the savings row only when a discount exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(CartTotalsBar(
      subtotalCents: 1000,
      discountCents: 0,
      totalCents: 1000,
      onCheckout: () {},
    )));
    expect(find.text('Savings'), findsNothing);

    await tester.pumpWidget(wrap(CartTotalsBar(
      subtotalCents: 1234,
      discountCents: 234,
      totalCents: 1000,
      onCheckout: () {},
    )));
    expect(find.text('Savings'), findsOneWidget);
    // Negative cents: the locale places the sign ("-$2.34" en, "‏-2.34 $" ar).
    expect(find.text(r'-$2.34'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/product_price_row.dart';

Future<void> pumpRow(
  WidgetTester tester,
  Product product, {
  TextStyle? finalPriceStyle,
  bool baseline = false,
  double gap = 6,
  bool showDiscountBadge = false,
  Locale? locale,
  double width = 200,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: ProductPriceRow(
              product: product,
              finalPriceStyle: finalPriceStyle,
              baseline: baseline,
              gap: gap,
              showDiscountBadge: showDiscountBadge,
            ),
          ),
        ),
      ),
    );

/// The card/detail paid-price style — a distinctive style proves
/// [ProductPriceRow.finalPriceStyle] is applied rather than the tile default.
const TextStyle probeStyle = TextStyle(
  color: Colors.blue,
  fontWeight: FontWeight.w600,
);

/// An undiscounted product shows only the paid price — no struck original,
/// no badge, in either variant.
Product plainProduct({int priceCents = 2000}) =>
    Product(id: 1, categoryId: 1, name: 'Classic Tee', priceCents: priceCents);

/// A 25%-off product: $20.00 original → $15.00 paid.
Product discountedProduct({int priceCents = 2000, int discountPercent = 25}) =>
    Product(
      id: 1,
      categoryId: 1,
      name: 'Classic Tee',
      priceCents: priceCents,
      discountPercent: discountPercent,
    );

void main() {
  testWidgets('tile variant: paid price only when undiscounted',
      (WidgetTester tester) async {
    await pumpRow(tester, plainProduct());

    expect(find.text(r'$20.00'), findsOneWidget);
    // No struck original or badge for a plain product.
    expect(find.byType(Flexible), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('tile variant: struck original sits in a Flexible, default '
      'bold-body style, center-aligned', (WidgetTester tester) async {
    await pumpRow(tester, discountedProduct());

    final paid = tester.widget<Text>(find.text(r'$15.00'));
    // The tile default paid price is bold body.
    expect(paid.style?.fontWeight, FontWeight.w600);
    final original = tester.widget<Text>(find.text(r'$20.00'));
    expect(original.style?.decoration, TextDecoration.lineThrough);

    // The struck price is the Flexible child (a tight column ellipsizes it).
    final flexible = find.ancestor(
      of: find.text(r'$20.00'),
      matching: find.byType(Flexible),
    );
    expect(flexible, findsOneWidget);

    // Tiles are center-aligned (baseline defaults to false).
    final row = tester.widget<Row>(find.byType(Row));
    expect(row.crossAxisAlignment, CrossAxisAlignment.center);
  });

  testWidgets('card variant: baseline-aligned with the caller style applied',
      (WidgetTester tester) async {
    await pumpRow(
      tester,
      discountedProduct(),
      finalPriceStyle: probeStyle,
      baseline: true,
    );

    // The paid price carries the caller style (color + weight prove it).
    final paid = tester.widget<Text>(find.text(r'$15.00'));
    expect(paid.style?.color, Colors.blue);
    expect(paid.style?.fontWeight, FontWeight.w600);

    final row = tester.widget<Row>(find.byType(Row));
    expect(row.crossAxisAlignment, CrossAxisAlignment.baseline);
    expect(row.textBaseline, TextBaseline.alphabetic);
  });

  testWidgets('badge variant: struck price stays whole, badge ellipsizes in '
      'a Flexible', (WidgetTester tester) async {
    await pumpRow(
      tester,
      discountedProduct(),
      baseline: true,
      gap: 8,
      showDiscountBadge: true,
    );

    expect(find.text(r'$15.00'), findsOneWidget); // paid
    expect(find.text(r'$20.00'), findsOneWidget); // struck
    expect(find.text('-25%'), findsOneWidget); // badge

    // The gap param is honored: 8px between the paid price's right edge and
    // the struck price (the detail treatment; the tiles use 6).
    final paid = tester.getTopLeft(find.text(r'$15.00'));
    final paidWidth = tester.getSize(find.text(r'$15.00')).width;
    final struckLeft = tester.getTopLeft(find.text(r'$20.00')).dx;
    expect(struckLeft - (paid.dx + paidWidth), 8);

    // The detail contract: the struck price is NOT flexible (stays whole),
    // the badge is the Flexible child (it ellipsizes).
    expect(
      find.ancestor(
        of: find.text(r'$20.00'),
        matching: find.byType(Flexible),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('-25%'),
        matching: find.byType(Flexible),
      ),
      findsOneWidget,
    );
  });

  testWidgets('badge variant renders Eastern digits under ar',
      (WidgetTester tester) async {
    // Wider box: ar adds bidi marks around prices, so the badge row needs
    // more room than the 200px en tile.
    await pumpRow(
      tester,
      discountedProduct(),
      showDiscountBadge: true,
      locale: const Locale('ar'),
      width: 400,
    );

    expect(find.text('-٢٥%'), findsOneWidget);
    expect(find.text('-25%'), findsNothing);
    // formatCents under ar keeps the Western decimal point and converts
    // only the digits ($15.00 → ١٥.٠٠).
    expect(find.textContaining('١٥.٠٠'), findsOneWidget);
    expect(find.textContaining('٢٠.٠٠'), findsOneWidget);
  });
}

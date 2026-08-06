import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/product_card.dart';

Future<void> pumpCard(WidgetTester tester, Product product,
        {VoidCallback? onTap}) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 280,
            child: ProductCard(product: product, onTap: onTap ?? () {}),
          ),
        ),
      ),
    );

Product product({
  int priceCents = 2000,
  int discountPercent = 0,
  int stock = 10,
}) =>
    Product(
      id: 1,
      categoryId: 1,
      name: 'Classic Tee',
      priceCents: priceCents,
      discountPercent: discountPercent,
      stock: stock,
    );

void main() {
  testWidgets('renders the name and final price', (WidgetTester tester) async {
    await pumpCard(tester, product());

    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text(r'$20.00'), findsOneWidget);
  });

  testWidgets('a discounted product shows the badge and struck-through price',
      (WidgetTester tester) async {
    await pumpCard(tester, product(priceCents: 2000, discountPercent: 25));

    expect(find.text('-25%'), findsOneWidget);
    final original = tester.widget<Text>(find.text(r'$20.00'));
    expect(original.style?.decoration, TextDecoration.lineThrough);
    expect(find.text(r'$15.00'), findsOneWidget); // final price
  });

  testWidgets('a low-stock product shows the remaining-count message',
      (WidgetTester tester) async {
    // lowStockThreshold is 5; stock 1-5 is low (but > 0 is not out).
    await pumpCard(tester, product(stock: 3));

    expect(find.text('Low stock: 3 left'), findsOneWidget);
  });

  testWidgets('an out-of-stock product shows the badge, not the low message',
      (WidgetTester tester) async {
    await pumpCard(tester, product(stock: 0));

    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.textContaining('Low stock'), findsNothing);
  });

  testWidgets('tapping the card fires onTap', (WidgetTester tester) async {
    var tapped = 0;
    await pumpCard(tester, product(), onTap: () => tapped++);

    await tester.tap(find.text('Classic Tee'));
    expect(tapped, 1);
  });
}

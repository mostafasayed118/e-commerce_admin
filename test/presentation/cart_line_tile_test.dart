import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/cart/cart_state.dart';
import 'package:shop_admin/presentation/features/cart/widgets/cart_line_tile.dart';

Future<void> pumpTile(WidgetTester tester, Widget tile, {Locale? locale}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: tile),
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

CartLine line({
  int quantity = 1,
  int priceCents = 2000,
  int discountPercent = 0,
  int stock = 10,
}) =>
    CartLine(
      product: product(
        priceCents: priceCents,
        discountPercent: discountPercent,
        stock: stock,
      ),
      quantity: quantity,
    );

void main() {
  testWidgets('renders the name, final price, and line total',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      CartLineTile(
        line: line(quantity: 2),
        onAdd: () {},
        onRemoveOne: () {},
      ),
    );

    expect(find.text('Classic Tee'), findsOneWidget);
    // Final price $20.00 and line total 2 x $20.00 = $40.00.
    expect(find.text(r'$20.00'), findsOneWidget);
    expect(find.text(r'$40.00'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // the quantity readout
  });

  testWidgets('a discounted product shows the struck-through original price',
      (WidgetTester tester) async {
    // Quantity 2: final price $15.00 each, line total $30.00 — so the
    // per-unit prices don't collide with the line total in the finders.
    await pumpTile(
      tester,
      CartLineTile(
        line: line(quantity: 2, priceCents: 2000, discountPercent: 25),
        onAdd: () {},
        onRemoveOne: () {},
      ),
    );

    final original = tester.widget<Text>(find.text(r'$20.00'));
    expect(original.style?.decoration, TextDecoration.lineThrough);
    expect(find.text(r'$15.00'), findsOneWidget); // final price
    expect(find.text(r'$30.00'), findsOneWidget); // line total
  });

  testWidgets('the stepper fires add and remove-one, and reads the quantity',
      (WidgetTester tester) async {
    var added = 0;
    var removed = 0;
    await pumpTile(
      tester,
      CartLineTile(
        line: line(quantity: 3),
        onAdd: () => added++,
        onRemoveOne: () => removed++,
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    expect(added, 1);
    expect(removed, 1);
    // Tooltips carry the localized labels.
    expect(find.byTooltip('Add one'), findsOneWidget);
    expect(find.byTooltip('Remove one'), findsOneWidget);
  });

  testWidgets('Arabic renders Eastern digits for the warning and quantity',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      CartLineTile(
        line: line(quantity: 5, stock: 3),
        onAdd: () {},
        onRemoveOne: () {},
      ),
      locale: const Locale('ar'),
    );

    expect(find.text('متبقي ٣ فقط في المخزون'), findsOneWidget);
    expect(find.text('٥'), findsOneWidget); // the quantity readout
  });

  testWidgets('a line exceeding stock warns and disables the + button',
      (WidgetTester tester) async {
    var added = 0;
    await pumpTile(
      tester,
      CartLineTile(
        // 5 in cart, only 3 in stock.
        line: line(quantity: 5, stock: 3),
        onAdd: () => added++,
        onRemoveOne: () {},
      ),
    );

    expect(find.text('Only 3 left in stock'), findsOneWidget);

    final addButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_circle_outline),
    );
    expect(addButton.onPressed, isNull);
  });
}

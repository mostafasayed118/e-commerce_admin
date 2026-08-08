import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/stock_status_label.dart';

Future<void> pumpLabel(WidgetTester tester, Product product,
        {TextStyle? style, bool showInStock = false, Locale? locale}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StockStatusLabel(
            product: product,
            style: style,
            showInStock: showInStock,
          ),
        ),
      ),
    );

/// Stock semantics follow the entity: 0 is out, 1–5 is low (threshold), >5
/// is in stock. A distinctive style (red caller color, larger size) proves
/// the status color *overlays* rather than replaces the caller's style.
const TextStyle probeStyle = TextStyle(color: Colors.red, fontSize: 22);

Product product({int stock = 10}) => Product(
      id: 1,
      categoryId: 1,
      name: 'Classic Tee',
      priceCents: 2000,
      stock: stock,
    );

Color schemeError(WidgetTester tester) => Theme.of(
      tester.element(find.byType(StockStatusLabel)),
    ).colorScheme.error;

Color schemePrimary(WidgetTester tester) => Theme.of(
      tester.element(find.byType(StockStatusLabel)),
    ).colorScheme.primary;

void main() {
  testWidgets('out of stock renders the message in the error color',
      (WidgetTester tester) async {
    await pumpLabel(tester, product(stock: 0), style: probeStyle);

    expect(find.text('Out of stock'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Out of stock'));
    // The status color wins over the caller's style color; size is kept.
    expect(text.style?.color, schemeError(tester));
    expect(text.style?.fontSize, 22);
  });

  testWidgets('low stock renders the remaining count in the error color',
      (WidgetTester tester) async {
    await pumpLabel(tester, product(stock: 3), style: probeStyle);

    expect(find.text('Low stock: 3 left'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Low stock: 3 left'));
    expect(text.style?.color, schemeError(tester));
    expect(text.style?.fontSize, 22);
  });

  testWidgets('in stock shows no label unless showInStock is true',
      (WidgetTester tester) async {
    await pumpLabel(tester, product(stock: 10));

    // The widget renders nothing (the defensive shrink branch).
    expect(find.text('In stock'), findsNothing);
    expect(find.textContaining('stock'), findsNothing);
  });

  testWidgets('in stock with showInStock renders in the primary color',
      (WidgetTester tester) async {
    await pumpLabel(
      tester,
      product(stock: 10),
      showInStock: true,
      style: probeStyle,
    );

    expect(find.text('In stock'), findsOneWidget);
    final text = tester.widget<Text>(find.text('In stock'));
    expect(text.style?.color, schemePrimary(tester));
    expect(text.style?.fontSize, 22);
  });

  testWidgets('Arabic: out of stock renders the Arabic message',
      (WidgetTester tester) async {
    await pumpLabel(
      tester,
      product(stock: 0),
      locale: const Locale('ar'),
    );

    expect(find.text('نفدت الكمية'), findsOneWidget);
    expect(find.text('Out of stock'), findsNothing);
  });

  testWidgets('Arabic: low stock renders Eastern digits',
      (WidgetTester tester) async {
    await pumpLabel(
      tester,
      product(stock: 3),
      locale: const Locale('ar'),
    );

    expect(find.text('كمية منخفضة: متبقي ٣'), findsOneWidget);
    expect(find.text('Low stock: 3 left'), findsNothing);
    expect(find.textContaining('3'), findsNothing);
  });

  testWidgets('Arabic: in stock renders the Arabic message',
      (WidgetTester tester) async {
    await pumpLabel(
      tester,
      product(stock: 10),
      showInStock: true,
      locale: const Locale('ar'),
    );

    expect(find.text('متوفر'), findsOneWidget);
    expect(find.text('In stock'), findsNothing);
  });
}

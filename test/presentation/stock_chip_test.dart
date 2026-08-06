import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/admin_catalog_state.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/product_list.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/stock_chip.dart';

/// Pumps the widget under the app's localization delegates (the widgets read
/// `context.l10n`), mirroring the other widget tests.
Future<void> pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('StockChip (direct contract)', () {
    testWidgets('renders the label with the given foreground and background',
        (WidgetTester tester) async {
      const chip = StockChip(
        label: 'Out of stock',
        color: Colors.red,
        background: Color(0xFFFFDDDD),
      );
      await pump(tester, chip);

      final text = tester.widget<Text>(find.text('Out of stock'));
      expect(text.style?.color, Colors.red);
      expect(text.style?.fontWeight, FontWeight.w600);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFDDDD));
      expect(decoration.borderRadius, BorderRadius.circular(999));
    });
  });

  group('StockChip tri-state via ProductList', () {
    Product product(int id, String name, int stock) => Product(
          id: id,
          categoryId: 1,
          name: name,
          priceCents: 1000,
          stock: stock,
        );

    Future<void> pumpList(WidgetTester tester, List<Product> products) async {
      final state = AdminCatalogLoaded(
        products: products,
        categories: [
          Category(id: 1, name: 'Clothing', createdAt: DateTime(2026)),
        ],
      );
      await pump(
        tester,
        ProductList(
          state: state,
          onEdit: (_) {},
          onDelete: (_) {},
          onCreate: () {},
        ),
      );
    }

    testWidgets('an out-of-stock product shows the Out of stock chip',
        (WidgetTester tester) async {
      await pumpList(tester, [product(1, 'Leather Belt', 0)]);
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('a low-stock product shows the Low stock chip',
        (WidgetTester tester) async {
      // lowStockThreshold is 5: stock 1-5 is low, but > 0 is not out.
      await pumpList(tester, [product(1, 'Wool Beanie', 3)]);
      expect(find.text('Low stock'), findsOneWidget);
    });

    testWidgets('an in-stock product shows the "{stock} in stock" chip',
        (WidgetTester tester) async {
      await pumpList(tester, [product(1, 'Classic Tee', 25)]);
      expect(find.text('25 in stock'), findsOneWidget);
    });

    testWidgets('the three stock states coexist on one list',
        (WidgetTester tester) async {
      await pumpList(tester, [
        product(1, 'Leather Belt', 0),
        product(2, 'Wool Beanie', 3),
        product(3, 'Classic Tee', 25),
      ]);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('Low stock'), findsOneWidget);
      expect(find.text('25 in stock'), findsOneWidget);
    });
  });
}

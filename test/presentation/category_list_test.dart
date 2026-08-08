import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/admin_catalog_state.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/category_list.dart';

/// Pumps the list under the app's localization delegates (it reads
/// `context.l10n` / `context.categoryName`), mirroring stock_chip_test.
Future<void> pumpList(
  WidgetTester tester, {
  required AdminCatalogLoaded state,
  required void Function(Category) onRename,
  required void Function(Category) onDelete,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CategoryList(
            state: state,
            onRename: onRename,
            onDelete: onDelete,
          ),
        ),
      ),
    );

Product productIn(int categoryId, {String name = 'Classic Tee'}) => Product(
      id: 1,
      categoryId: categoryId,
      name: name,
      priceCents: 1000,
      stock: 3,
    );

void main() {
  testWidgets('an empty list shows the no-categories message view',
      (WidgetTester tester) async {
    await pumpList(
      tester,
      state: AdminCatalogLoaded(products: const [], categories: const []),
      onRename: (_) {},
      onDelete: (_) {},
    );

    expect(find.text('No categories yet'), findsOneWidget);
    expect(
      find.text('Create a category before adding products.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.category_outlined), findsOneWidget);
  });

  testWidgets('renders each category with its product count and actions',
      (WidgetTester tester) async {
    await pumpList(
      tester,
      state: AdminCatalogLoaded(
        products: [productIn(1), productIn(1, name: 'Denim Jacket')],
        categories: const [Category(id: 1, name: 'Clothing')],
      ),
      onRename: (_) {},
      onDelete: (_) {},
    );

    expect(find.text('Clothing'), findsOneWidget);
    expect(find.text('2 products'), findsOneWidget); // per-row product count
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('wires rename and delete to the callbacks',
      (WidgetTester tester) async {
    final renamed = <Category>[];
    final deleted = <Category>[];
    const clothing = Category(id: 1, name: 'Clothing');
    await pumpList(
      tester,
      state: AdminCatalogLoaded(
        products: const [],
        categories: const [clothing],
      ),
      onRename: renamed.add,
      onDelete: deleted.add,
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(renamed, [clothing]);

    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deleted, [clothing]);
  });

  testWidgets('Arabic renders the localized name and Eastern-digit count',
      (WidgetTester tester) async {
    await pumpList(
      tester,
      state: AdminCatalogLoaded(
        products: [
          productIn(1),
          productIn(1, name: 'Denim Jacket'),
          productIn(1, name: 'Wool Beanie'),
        ],
        categories: const [
          Category(id: 1, name: 'Clothing', nameAr: 'ملابس'),
        ],
      ),
      onRename: (_) {},
      onDelete: (_) {},
      locale: const Locale('ar'),
    );

    expect(find.text('ملابس'), findsOneWidget);
    // 3 منتجات — the count converts to Eastern digits.
    expect(find.text('٣ منتجات'), findsOneWidget);
    expect(find.text('3 منتجات'), findsNothing);
  });
}

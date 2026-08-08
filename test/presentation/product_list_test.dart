import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/admin_catalog_state.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/product_list.dart';

Future<void> pumpList(
  WidgetTester tester, {
  required AdminCatalogLoaded state,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProductList(
            state: state,
            onEdit: (_) {},
            onDelete: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );

void main() {
  final tee = Product(
    id: 1,
    categoryId: 1,
    name: 'Classic Tee',
    priceCents: 2000,
    discountPercent: 25,
    stock: 5,
  );

  testWidgets('shows category, discounted price and the discount note',
      (WidgetTester tester) async {
    await pumpList(
      tester,
      state: AdminCatalogLoaded(
        products: [tee],
        categories: const [Category(id: 1, name: 'Clothing')],
      ),
    );

    expect(find.text(r'Clothing · $15.00 (25% off)'), findsOneWidget);
  });

  testWidgets('Arabic renders Eastern digits in the stock chip',
      (WidgetTester tester) async {
    await pumpList(
      tester,
      state: AdminCatalogLoaded(
        products: [
          Product(
            id: 2,
            categoryId: 1,
            name: 'Denim Jacket',
            priceCents: 4500,
            stock: 10,
          ),
        ],
        categories: const [Category(id: 1, name: 'Clothing')],
      ),
      locale: const Locale('ar'),
    );

    // A fully-stocked product shows its count in the chip, localized.
    expect(find.text('١٠ في المخزون'), findsOneWidget);
  });

  testWidgets('Arabic renders Eastern digits for the price and percent',
      (WidgetTester tester) async {
    await pumpList(
      tester,
      state: AdminCatalogLoaded(
        products: [tee],
        categories: const [
          Category(id: 1, name: 'Clothing', nameAr: 'ملابس'),
        ],
      ),
      locale: const Locale('ar'),
    );

    // intl's ar currency pattern carries bidi marks around the amount, so
    // assert the stable parts rather than the exact bytes (like money_test).
    expect(find.textContaining('ملابس ·'), findsOneWidget);
    expect(find.textContaining('١٥.٠٠'), findsOneWidget); // price
    expect(find.textContaining('خصم ٢٥%'), findsOneWidget);
    expect(find.textContaining('15.00'), findsNothing);
  });
}

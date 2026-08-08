import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/stock_status_label.dart';
import 'package:shop_admin/presentation/features/wishlist/wishlist_state.dart';
import 'package:shop_admin/presentation/features/wishlist/widgets/wishlist_tile.dart';

/// Pumps the tile under the app's localization delegates (it reads
/// `context.l10n` / `context.productName` / `context.formatCents`).
Future<void> pumpTile(
  WidgetTester tester,
  WishlistTile tile, {
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: tile),
      ),
    );

Product product({int stock = 10, int priceCents = 2000}) => Product(
      id: 1,
      categoryId: 1,
      name: 'Classic Tee',
      priceCents: priceCents,
      stock: stock,
    );

void main() {
  testWidgets('renders the name, price, stock line, and move-to-cart button',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      WishlistTile(
        line: WishlistLine(product: product(stock: 3)),
        onRemove: () {},
        onMoveToCart: () {},
      ),
    );

    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text(r'$20.00'), findsOneWidget);
    expect(find.text('Low stock: 3 left'), findsOneWidget);
    expect(find.text('Move to cart'), findsOneWidget);
    expect(find.byTooltip('Remove from wishlist'), findsOneWidget);
  });

  testWidgets('an out-of-stock product shows the out-of-stock line',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      WishlistTile(
        line: WishlistLine(product: product(stock: 0)),
        onRemove: () {},
        onMoveToCart: () {},
      ),
    );

    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.text('In stock'), findsNothing);
  });

  testWidgets('an in-stock product renders no stock line',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      WishlistTile(
        line: WishlistLine(product: product()),
        onRemove: () {},
        onMoveToCart: () {},
      ),
    );

    // The tile only renders out-of-stock/low-stock lines.
    expect(find.byType(StockStatusLabel), findsNothing);
  });

  testWidgets('wires the remove and move-to-cart callbacks',
      (WidgetTester tester) async {
    var removed = false;
    var moved = false;
    await pumpTile(
      tester,
      WishlistTile(
        line: WishlistLine(product: product()),
        onRemove: () => removed = true,
        onMoveToCart: () => moved = true,
      ),
    );

    await tester.tap(find.byTooltip('Remove from wishlist'));
    expect(removed, isTrue);

    await tester.tap(find.text('Move to cart'));
    expect(moved, isTrue);
  });

  testWidgets('Arabic renders the stock count in Eastern digits and localized labels',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      WishlistTile(
        line: WishlistLine(product: product(stock: 3)),
        onRemove: () {},
        onMoveToCart: () {},
      ),
      locale: const Locale('ar'),
    );

    expect(find.text('كمية منخفضة: متبقي ٣'), findsOneWidget);
    expect(find.text('نقل إلى السلة'), findsOneWidget);
    expect(find.text('Low stock: 3 left'), findsNothing);
    expect(find.text('Move to cart'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/low_stock_tile.dart';

/// Pumps the tile under the app's localization delegates (it reads
/// `context.l10n` / `context.productName` / `context.formatCents`).
Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Product product({int stock = 3, int priceCents = 2000}) => Product(
      id: 1,
      categoryId: 1,
      name: 'Classic Tee',
      priceCents: priceCents,
      stock: stock,
    );

void main() {
  testWidgets('an out-of-stock product shows the block icon and label',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(LowStockTile(product: product(stock: 0))));

    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.byIcon(Icons.block), findsOneWidget);
    // The price renders through the active locale's formatter.
    expect(find.text(r'$20.00'), findsOneWidget);
  });

  testWidgets('a low-stock product shows the warning icon and remaining count',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(LowStockTile(product: product(stock: 3))));

    expect(find.text('Only 3 left'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('tapping navigates to the product edit form',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: LowStockTile(product: product())),
        ),
        GoRoute(
          path: '/admin/products/:productId/edit',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('edit form'))),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));

    await tester.tap(find.text('Classic Tee'));
    await tester.pumpAndSettle();
    expect(find.text('edit form'), findsOneWidget);
  });
}

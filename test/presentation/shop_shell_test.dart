import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/cart/cart_cubit.dart';
import 'package:shop_admin/presentation/shells/shop_shell.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// A minimal shop shell route so [ShopShell] gets a real
/// [StatefulNavigationShell] (built by go_router — not mockable).
GoRouter shopRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              ShopShell(navigationShell),
          branches: [
            for (final path in ['/', '/cart', '/orders', '/profile'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) =>
                        const Center(child: Text('content')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

Future<void> pumpShopShell(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: shopRouter(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  testWidgets('the cart badge shows the live item count and hides at zero',
      (WidgetTester tester) async {
    // Seed a product and a cart row directly (the real drift database), so
    // the DI CartCubit's watch streams emit a non-empty cart on subscribe.
    // A category row is required first — foreign keys are enforced (ON).
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'Clothing', createdAt: 1),
        );
    final productId = await db.into(db.products).insert(
          ProductsCompanion.insert(
            categoryId: categoryId,
            name: 'Classic Tee',
            priceCents: 2000,
            discountPercent: 0,
            stock: 25,
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await db.into(db.cartItems).insert(
          CartItemsCompanion.insert(
            // productId is the (non-autoIncrement) primary key → Value().
            productId: drift.Value(productId),
            quantity: 2,
            addedAt: 1,
          ),
        );

    // Access the DI cubit so its subscriptions exist before the shell builds.
    final cartCubit = getIt<CartCubit>();

    await pumpShopShell(tester);
    await settleDrift(tester); // deliver the cubit's initial watch emissions
    await tester.pumpAndSettle();

    // Badge shows the live count on the Cart destination.
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.descendant(
          of: find.byType(Badge),
          matching: find.text('2'),
        ),
      ),
      findsOneWidget,
    );

    // Other destinations have no badge.
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.descendant(
          of: find.byType(Badge),
          matching: find.text('1'),
        ),
      ),
      findsNothing,
    );

    // Empty the cart: the badge must disappear (0 hides the label).
    await cartCubit.clear();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.descendant(
          of: find.byType(Badge),
          matching: find.text('0'),
        ),
      ),
      findsNothing,
    );

    await unmountApp(tester);
  });
}

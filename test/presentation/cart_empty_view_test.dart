import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/cart/widgets/cart_empty_view.dart';

/// Pumps the empty view under the app's localization delegates (it reads
/// `context.l10n`) plus a GoRouter (the CTA navigates with `context.go`).
Widget wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders the empty-cart icon, title, and message',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const CartEmptyView()));

    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(
      find.text('Add something you like from the catalog.'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic renders the localized copy',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(const CartEmptyView(), locale: const Locale('ar')),
    );

    expect(find.text('سلتك فارغة'), findsOneWidget);
    expect(find.text('أضف ما يعجبك من المتجر.'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsNothing);
  });

  testWidgets('the browse-products CTA navigates back to the catalog',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        GoRoute(
          path: '/cart',
          builder: (context, state) => const Scaffold(body: CartEmptyView()),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('catalog'))),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));

    await tester.tap(find.text('Browse products'));
    await tester.pumpAndSettle();

    expect(find.text('catalog'), findsOneWidget);
  });
}

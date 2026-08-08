import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/wishlist/widgets/wishlist_empty_view.dart';

/// Pumps the empty view under the app's localization delegates (it reads
/// `context.l10n`) plus a GoRouter (the CTA navigates with `context.go`).
Widget wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders the empty-wishlist icon, title, and message',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const WishlistEmptyView()));

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('Your wishlist is empty'), findsOneWidget);
    expect(
      find.text('Tap the heart on any product to save it for later.'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic renders the localized copy',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(const WishlistEmptyView(), locale: const Locale('ar')),
    );

    expect(find.text('قائمة المفضلة فارغة'), findsOneWidget);
    expect(
      find.text('اضغط على القلب في أي منتج لحفظه لوقت لاحق.'),
      findsOneWidget,
    );
    expect(find.text('Your wishlist is empty'), findsNothing);
  });

  testWidgets('the browse-products CTA navigates back to the catalog',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/wishlist',
      routes: [
        GoRoute(
          path: '/wishlist',
          builder: (context, state) =>
              const Scaffold(body: WishlistEmptyView()),
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

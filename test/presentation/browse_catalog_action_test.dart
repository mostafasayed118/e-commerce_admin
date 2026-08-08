import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/widgets/browse_catalog_action.dart';

/// Pumps the button under the app's localization delegates (it reads
/// `context.l10n`) and a GoRouter (it navigates with `context.go`), mirroring
/// the other router-using widget tests.
Widget wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders the storefront icon and English label', (tester) async {
    await tester.pumpWidget(wrap(const BrowseCatalogAction()));

    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.text('Browse products'), findsOneWidget);
  });

  testWidgets('Arabic renders the localized label', (tester) async {
    await tester.pumpWidget(wrap(
      const BrowseCatalogAction(),
      locale: const Locale('ar'),
    ));

    expect(find.text('تصفح المنتجات'), findsOneWidget);
    expect(find.text('Browse products'), findsNothing);
  });

  testWidgets('tapping navigates back to the catalog root', (tester) async {
    final router = GoRouter(
      initialLocation: '/empty',
      routes: [
        GoRoute(
          path: '/empty',
          builder: (context, state) =>
              const Scaffold(body: BrowseCatalogAction()),
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

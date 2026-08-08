import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/widgets/admin_storefront_action.dart';

void main() {
  testWidgets('renders the storefront icon with the localized tooltip',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(actions: const [AdminStorefrontAction()]),
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    // The tooltip is resolved inside the widget (locale-aware).
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, 'Back to store');
  });

  testWidgets('Arabic resolves the tooltip in Arabic',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(actions: const [AdminStorefrontAction()]),
          body: const SizedBox(),
        ),
      ),
    );

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, 'العودة إلى المتجر');
  });

  testWidgets('tapping navigates back to the storefront root',
      (WidgetTester tester) async {
    // Mirrors the storefront-exit contract: the action only navigates to '/',
    // it never touches the admin unlock state.
    final router = GoRouter(
      initialLocation: '/admin/products',
      routes: [
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => Scaffold(
            appBar: AppBar(actions: const [AdminStorefrontAction()]),
            body: const Center(child: Text('admin form')),
          ),
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

    await tester.tap(find.byIcon(Icons.storefront_outlined));
    await tester.pumpAndSettle();

    expect(find.text('catalog'), findsOneWidget);
  });
}

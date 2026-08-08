import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/l10n/app_localizations.dart';

/// Wraps a [GoRouter] in the app's localization delegates, mirroring what
/// [ShopAdminApp] does — the flow tests pump the raw router (not the app
/// root), and every screen now reads `context.l10n`, so without the delegates
/// those tests would throw. The default platform locale (en_US) resolves to
/// English, keeping existing string assertions intact.
/// [locale] defaults to null (the platform locale → English). Flow tests that
/// need Arabic from the start (e.g. the admin overview's Eastern digits) pass
/// `const Locale('ar')` — the router tree is built with that locale, since
/// these tests pump the raw router rather than [ShopAdminApp]'s
/// LocaleCubit-driven MaterialApp.
Widget testApp(GoRouter router, {Locale? locale}) => MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );

/// Pumps a bare router at [size] via [testApp], restoring the surface after
/// the test — the widget-level counterpart to the flow pumps in
/// shop_flow.dart (no seeding or settling; the shell/form widget tests want
/// a fast, focused pump). [size] is required so the harness picks a surface
/// that lays its content out without scrolling.
Future<void> pumpRouterSurface(
  WidgetTester tester, {
  required GoRouter router,
  required Size size,
  Locale? locale,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(testApp(router, locale: locale));
}

/// Shared helpers for driving the customer-side (shop) flows in full-app
/// tests.
///
/// The shop flow tests (orders, cart, wishlist, profile, catalog, checkout)
/// each re-declared the same pump shape, nav switches, and the add-Classic-Tee
/// walk. These helpers are the single source for those gestures — the
/// admin-side equivalent lives in admin_flow.dart, and shell destination
/// switching (shared by both sides) lives in nav.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/presentation/app.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

import 'drift_settle.dart';
import 'test_app.dart';

/// Pumps the app on the real router (the flow tests' standard pump) and
/// returns the router — the caller assigns it to its `late GoRouter router`
/// field so tearDown can dispose it. [size] defaults to a phone surface; the
/// checkout test uses a taller one so the whole form fits, and the admin
/// flow tests use 900x1600/900x2200 so the rail layout shows and every list
/// tile is visible without scrolling. [seed] defaults to true; the
/// fresh-install tests pass false. [locale] passes through to [testApp] for
/// Arabic pumps (the admin overview test).
Future<GoRouter> pumpRouterApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool seed = true,
  Locale? locale,
}) async {
  final router = buildAppRouter();
  await _pumpApp(
    tester,
    size: size,
    seed: seed,
    child: testApp(router, locale: locale),
  );
  return router;
}

/// Pumps the full [ShopAdminApp] (the app's own MaterialApp.router wiring,
/// DI-driven locale/theme) — used where a test needs the app-level
/// composition (the catalog, localization, and app-boot tests). [seed]
/// defaults to true; the app-boot tests pump a fresh install.
Future<void> pumpFullApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool seed = true,
}) async {
  await _pumpApp(tester, size: size, seed: seed, child: const ShopAdminApp());
}

/// The shared pump tail of both pump helpers: surface, (optional) seed,
/// pump, and settle. Seeding runs inside `tester.runAsync` — testWidgets'
/// FakeAsync zone cannot see drift's background-isolate responses (see
/// drift_settle.dart).
Future<void> _pumpApp(
  WidgetTester tester, {
  required Size size,
  required bool seed,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  if (seed) {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
  }
  await tester.pumpWidget(child);
  await settleDrift(tester);
  await tester.pumpAndSettle();
}

/// Adds Classic Tee (qty 1) through the detail screen, then returns to the
/// catalog. Assumes the catalog is the current screen.
Future<void> addClassicTee(WidgetTester tester) async {
  await tester.tap(find.text('Classic Tee'));
  await settleAction(tester);

  await tester.tap(find.text('Add to Cart'));
  await settleAction(tester, delay: const Duration(milliseconds: 200));

  await tester.pageBack();
  await tester.pumpAndSettle();

  // Flush the "added to cart" SnackBar: it floats over the bottom of the
  // screen and would otherwise swallow taps on the cart's Checkout button.
  await settleSnackBar(tester);
}

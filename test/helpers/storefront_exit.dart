/// Shared assertions for the storefront exit affordance.
///
/// The exit exists at two levels: the shell-level rail/bar entry (AdminShell's
/// `exitAction` — a raw icon + visible label) and the pushed-screen AppBar
/// action ([AdminStorefrontAction] — gate, forms, order detail). Tests pin
/// both; these helpers are the single source so a rename or locale change
/// updates one place instead of five.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/features/admin/widgets/admin_storefront_action.dart';

/// The exit's localized text (tooltip on pushed screens, rail label in the
/// shell) — mirrors the ARB `backToStore` key.
const String storefrontExitEn = 'Back to store';
const String storefrontExitAr = 'العودة إلى المتجر';

/// The shared en/ar lookup for the exit-label and catalog-product assertions
/// — the single home of the `languageCode == 'ar'` ternary. Parameter order
/// mirrors the `...En` / `...Ar` const pairings above.
String _localized(Locale locale, String en, String ar) =>
    locale.languageCode == 'ar' ? ar : en;

/// Asserts the pushed-screen [AdminStorefrontAction] renders exactly once,
/// with its branded icon. Pass [reason] to say which screen is being pinned.
void expectStorefrontAction({String? reason}) {
  expect(find.byType(AdminStorefrontAction), findsOneWidget, reason: reason);
  expect(
    find.byIcon(AdminStorefrontAction.icon),
    findsOneWidget,
    reason: reason,
  );
}

/// Asserts the exit's *tooltip* (the IconButton on pushed screens) shows
/// [locale]'s translation.
void expectStorefrontTooltip(Locale locale, {String? reason}) {
  expect(
    find.byTooltip(_localized(locale, storefrontExitEn, storefrontExitAr)),
    findsOneWidget,
    reason: reason,
  );
}

/// Asserts the exit's *visible label* (the shell rail/bar entry) shows
/// [locale]'s translation.
void expectStorefrontLabel(Locale locale, {String? reason}) {
  expect(
    find.text(_localized(locale, storefrontExitEn, storefrontExitAr)),
    findsOneWidget,
    reason: reason,
  );
}

/// The seeded catalog's headline product in each locale — the anchor the
/// 'back at the store' assertion checks (mirrors SeedData's Classic Tee).
const String storefrontCatalogProductEn = 'Classic Tee';
const String storefrontCatalogProductAr = 'تيشيرت كلاسيك';

/// Taps the visible storefront exit. `hitTestable()` resolves the on-stage
/// one: the shop shell's Shop tab shares the storefront icon and the admin
/// shell keeps visited branches alive, so the icon can exist off-stage.
Future<void> tapStorefrontExit(WidgetTester tester) async {
  await tester.tap(find.byIcon(AdminStorefrontAction.icon).hitTestable());
}

/// Taps the visible storefront exit, settles the navigation, and asserts the
/// customer catalog is showing via its localized headline product — the
/// shared 'back at the store' verification.
///
/// Requires a seeded app pump (the flow tests' full-app pumps seed) on a
/// surface tall enough to keep the headline product on-screen (the flow
/// tests use 900x2200). Pass [locale] for Arabic pumps, which render Arabic
/// product names.
Future<void> tapStorefrontExitToStore(
  WidgetTester tester, {
  Locale? locale,
}) async {
  await tapStorefrontExit(tester);
  await tester.pumpAndSettle();
  expect(
    find.text(
      _localized(
        locale ?? const Locale('en'),
        storefrontCatalogProductEn,
        storefrontCatalogProductAr,
      ),
    ),
    findsOneWidget,
    reason: 'back at the customer catalog',
  );
}

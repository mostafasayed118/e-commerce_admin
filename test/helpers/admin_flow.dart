/// Shared helpers for driving the admin area in full-app flow tests.
///
/// The four admin flow tests (catalog, coupons, orders, overview) and the
/// form-push test each re-declared the same unlock walk, FAB tap, and form
/// pop. These helpers are the single source for those gestures — the two
/// pump styles (router-based vs full-app Profile navigation) fold into
/// [unlockAdmin]'s optional [GoRouter] parameter. Shell destination
/// switching now lives in nav.dart (shared with the shop flows).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'drift_settle.dart';

/// Unlocks the admin gate and lands on the overview — one walk for both
/// pump styles, discriminated by [router]:
///
/// * Pass [router] (the router-based pumps): `router.go('/admin/gate')`,
///   sets the PIN on a fresh DB, and asserts the route landed on
///   `/admin/overview`.
/// * Omit it (the full-app pumps): walks the user's real path Profile →
///   admin entry → PIN form, and asserts the overview title on the shell
///   rail + AppBar (both carry it).
///
/// Label parameters follow the pumped locale (the Arabic tests pass Arabic
/// labels). Pass [setPinTitle] to also pin the set-branch heading — the
/// catalog/coupons flows and the form-push flow's profile walk do. (The
/// profile walk used to assert it unconditionally; when calling without a
/// [router], pass it to keep that invariant.)
Future<void> unlockAdmin(
  WidgetTester tester, {
  GoRouter? router,
  String profileLabel = 'Profile',
  String? setPinTitle,
  String setPinLabel = 'Set PIN',
  String overviewLabel = 'Overview',
}) async {
  if (router != null) {
    router.go('/admin/gate');
  } else {
    await tester.tap(find.text(profileLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-admin-entry')));
  }
  await settleAction(tester); // gate's isPinSet() query

  if (setPinTitle != null) {
    expect(find.text(setPinTitle), findsOneWidget);
  }
  await _submitPin(tester, setPinLabel);

  if (router != null) {
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/admin/overview',
    );
  } else {
    // The admin rail + overview AppBar both carry the title.
    expect(find.text(overviewLabel), findsWidgets);
  }
}

/// Enters the demo PIN and taps the gate's submit button, settling the
/// resulting navigation — the shared tail of both unlock walks.
Future<void> _submitPin(WidgetTester tester, String setPinLabel) async {
  await tester.enterText(find.byType(TextField), '1234');
  await tester.tap(find.text(setPinLabel));
  await settleAdminWrite(tester);
}

/// Settles a drift write triggered by an admin action (form save, status
/// move, delete): the 200ms [settleAction] — the write's background-isolate
/// round-trip needs a real-async window.
Future<void> settleAdminWrite(WidgetTester tester) =>
    settleAction(tester, delay: const Duration(milliseconds: 200));

/// Taps the active branch's FAB. `hitTestable()` resolves the visible one —
/// the other built branches' FABs are kept alive in the shell's IndexedStack
/// (that coexistence is exactly what the form-push hero-tag test is about).
Future<void> tapAdminFab(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton).hitTestable());
  await tester.pumpAndSettle();
}

/// Pops a pushed admin form via its Material [BackButton].
Future<void> popAdminForm(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

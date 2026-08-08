/// Shared shell-navigation helpers for the full-app flow tests.
///
/// The admin flow tests re-declared `goToAdminBranch`/`goToAdminBranchByLabel`
/// and the shop flow tests re-declared `goToShopBranch`/`goToShopTab` — two
/// copies of the same two gestures (switch a shell destination by router
/// path, and by tapping its label). These are the single source for both,
/// since the admin rail and the shop bar/rail behave identically from the
/// driver's seat.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'drift_settle.dart';

/// Switches a shell destination by router path (the flow tests' style):
/// `router.go(path)` then settles the destination cubit's watch streams.
Future<void> goToDestination(
  WidgetTester tester,
  GoRouter router,
  String path,
) async {
  router.go(path);
  await settleAction(tester); // the destination cubit's watch streams
}

/// Switches a shell destination by tapping its rail/bar label (the
/// tap-driven flows' style). The bare text finder is exact at tap time —
/// the destination labels are unique to the shell's rail/bar (the admin
/// rail's and the shop bar's differ), and the screen title reflects the
/// *current* destination, not the tapped one.
Future<void> goToDestinationByLabel(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await settleAction(tester); // the destination cubit's watch streams
}

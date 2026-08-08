import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yields to the real event loop so background-isolate drift responses can be
/// delivered, then pumps one frame.
///
/// `testWidgets` runs under a FakeAsync zone, where real asynchronous events
/// — like drift's background-isolate query results and watch-stream emissions
/// — are invisible. `tester.runAsync` runs its callback in the real zone,
/// letting those responses land; the following `pump` rebuilds with the new
/// state. Call this after pumping the app or after any action that triggers a
/// database read/write (navigation to a drift-backed screen, a use-case call,
/// etc.), then follow with `pumpAndSettle` for animations.
Future<void> settleDrift(
  WidgetTester tester, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await tester.runAsync(() => Future<void>.delayed(delay));
  await tester.pump();
}

/// Settles an action's aftermath: pumps the tap's frame, yields to the real
/// event loop for the triggered drift read/write to land ([delay], matching
/// [settleDrift]), then settles animations.
///
/// The standard tail after any action that triggers a database round-trip —
/// navigation to a drift-backed screen, a use-case call, a form save.
/// [delay] is the drift write's settle window (default 100ms; longer writes
/// like order placement pass 300ms).
Future<void> settleAction(
  WidgetTester tester, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await tester.pump();
  await settleDrift(tester, delay: delay);
  await tester.pumpAndSettle();
}

/// Advances past a SnackBar's auto-dismiss timer and settles its exit
/// animation.
///
/// A SnackBar (the "added to cart" toast etc.) auto-dismisses on a 4s timer;
/// under FakeAsync the timer stays pending and the bar's exit animation must
/// be pumped through before the test interacts again or unmounts. Call this
/// after any action that showed a SnackBar — a floating bar can swallow taps
/// (e.g. the cart's Checkout button) and the pending timer trips the
/// pending-timer invariant at teardown.
Future<void> settleSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Unmounts the widget tree and flushes drift's cleanup timers.
///
/// Disposing the app closes every Cubit, which cancels its drift watch
/// subscriptions; drift then schedules a *zero-duration* timer for its query-
/// store cleanup. Under FakeAsync that timer is still "pending" when the test
/// ends, tripping the pending-timer invariant. Unmounting explicitly and
/// advancing the clock lets it fire. Call as the last step of any test that
/// pumped the app (after flushing any long UI timers — see [settleSnackBar]).
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}

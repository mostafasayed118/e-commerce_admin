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

/// Unmounts the widget tree and flushes drift's cleanup timers.
///
/// Disposing the app closes every Cubit, which cancels its drift watch
/// subscriptions; drift then schedules a *zero-duration* timer for its query-
/// store cleanup. Under FakeAsync that timer is still "pending" when the test
/// ends, tripping the pending-timer invariant. Unmounting explicitly and
/// advancing the clock lets it fire. Call as the last step of any test that
/// pumped the app (and after flushing any long UI timers, e.g. SnackBars).
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}

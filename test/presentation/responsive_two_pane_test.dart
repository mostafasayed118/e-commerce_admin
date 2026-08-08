import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/widgets/responsive/responsive_two_pane.dart';

/// Isolated tests for the shared [ResponsiveTwoPane] widget: stacked Column
/// below the breakpoint, side-by-side Row at/above it, both panes Expanded.
/// Each test sets the surface size explicitly so the widths below are not
/// clamped to the default 800px viewport.
void main() {
  Future<void> setSurface(WidgetTester tester, double width) async {
    await tester.binding.setSurfaceSize(Size(width, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SizedBox(height: 600, child: child)),
      );

  const left = SizedBox(key: Key('left'), width: 40, height: 40);
  const right = SizedBox(key: Key('right'), width: 40, height: 40);

  testWidgets('below the breakpoint the panes stack in a Column',
      (WidgetTester tester) async {
    await setSurface(tester, 500);
    await tester.pumpWidget(
      wrap(const ResponsiveTwoPane(left: left, right: right)),
    );

    expect(find.byKey(const Key('left')), findsOneWidget);
    expect(find.byKey(const Key('right')), findsOneWidget);
    // Column layout: the panes share the vertical axis.
    final leftBox = tester.getTopLeft(find.byKey(const Key('left')));
    final rightBox = tester.getTopLeft(find.byKey(const Key('right')));
    expect(leftBox.dx, rightBox.dx);
    expect(rightBox.dy, greaterThan(leftBox.dy));
  });

  testWidgets('at and above the breakpoint the panes sit side by side',
      (WidgetTester tester) async {
    // Exactly at the default 1000 breakpoint.
    await setSurface(tester, 1000);
    await tester.pumpWidget(
      wrap(const ResponsiveTwoPane(left: left, right: right)),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('right'))).dx,
      greaterThan(tester.getTopLeft(find.byKey(const Key('left'))).dx),
    );

    await setSurface(tester, 1400);
    await tester.pumpWidget(
      wrap(const ResponsiveTwoPane(left: left, right: right)),
    );
    // Row layout: the panes share the horizontal axis.
    final leftBox = tester.getTopLeft(find.byKey(const Key('left')));
    final rightBox = tester.getTopLeft(find.byKey(const Key('right')));
    expect(leftBox.dy, rightBox.dy);
    expect(rightBox.dx, greaterThan(leftBox.dx));
  });

  testWidgets('panes are Expanded so a wide right pane never overflows wide content',
      (WidgetTester tester) async {
    await setSurface(tester, 800);
    // A wide right child must be shrunk into its Expanded slot, not overflow.
    await tester.pumpWidget(
      wrap(
        const ResponsiveTwoPane(
          left: SizedBox(width: 100, height: 100),
          right: SizedBox(width: 600, height: 100),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a custom breakpoint changes where the split happens',
      (WidgetTester tester) async {
    const pane = ResponsiveTwoPane(
      left: left,
      right: right,
      breakpoint: 600,
    );
    await setSurface(tester, 500);
    await tester.pumpWidget(wrap(pane));
    // Below 600: stacked (Column).
    final leftBox = tester.getTopLeft(find.byKey(const Key('left')));
    final rightBox = tester.getTopLeft(find.byKey(const Key('right')));
    expect(leftBox.dx, rightBox.dx);

    await setSurface(tester, 600);
    await tester.pumpWidget(wrap(pane));
    // At 600: side by side (Row).
    expect(
      tester.getTopLeft(find.byKey(const Key('right'))).dx,
      greaterThan(tester.getTopLeft(find.byKey(const Key('left'))).dx),
    );
  });
}

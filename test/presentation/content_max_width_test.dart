import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/widgets/responsive/content_max_width.dart';
import 'package:shop_admin/presentation/widgets/responsive/responsive_breakpoints.dart';

/// Isolated tests for the shared [ContentMaxWidth] widget: it must be a
/// no-op below [maxWidth] (content keeps its full width) and cap + center
/// above it. Each test sets the surface size explicitly so the widths below
/// are not clamped to the default 800px viewport.
///
/// The child's laid-out width is measured (the [Align] wrapper always fills
/// the available width — it is the SizedBox the widget hands to [child] that
/// enforces the cap).
void main() {
  const child = SizedBox(key: Key('content'), width: 200, height: 50);

  Widget wrap(Widget child, double width) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: 600, child: child),
        ),
      );

  Future<void> setSurface(WidgetTester tester, double width) async {
    await tester.binding.setSurfaceSize(Size(width, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  /// The laid-out width of the child inside the [ContentMaxWidth].
  double contentWidth(WidgetTester tester) =>
      tester.renderObject<RenderBox>(find.byKey(const Key('content'))).size.width;

  testWidgets('below maxWidth the child keeps the full available width',
      (WidgetTester tester) async {
    await setSurface(tester, 400);
    await tester.pumpWidget(wrap(const ContentMaxWidth(child: child), 400));

    // 400 < 1200 default max: no capping, the full width is used.
    expect(contentWidth(tester), 400);
  });

  testWidgets('above maxWidth the child is capped and centered',
      (WidgetTester tester) async {
    await setSurface(tester, 2000);
    await tester.pumpWidget(wrap(const ContentMaxWidth(child: child), 2000));

    expect(contentWidth(tester), ResponsiveBreakpoints.contentMaxWidth);
    // Centered: equal empty gutters on both sides.
    final leftGap = 2000 - ResponsiveBreakpoints.contentMaxWidth;
    final box = tester.renderObject<RenderBox>(find.byKey(const Key('content')));
    expect(box.localToGlobal(Offset.zero).dx, leftGap / 2);
  });

  testWidgets('a custom maxWidth (forms) caps at that width',
      (WidgetTester tester) async {
    await setSurface(tester, 2000);
    await tester.pumpWidget(
      wrap(
        const ContentMaxWidth(
          maxWidth: ResponsiveBreakpoints.formMaxWidth,
          child: child,
        ),
        2000,
      ),
    );

    expect(contentWidth(tester), ResponsiveBreakpoints.formMaxWidth);
  });

  testWidgets('keeps full height so Expanded children keep working',
      (WidgetTester tester) async {
    await setSurface(tester, 2000);
    // A Column with an Expanded child must not collapse to intrinsic height.
    await tester.pumpWidget(
      wrap(
        const ContentMaxWidth(
          child: Column(
            children: [
              Expanded(child: ColoredBox(color: Colors.red)),
              SizedBox(height: 20, child: ColoredBox(color: Colors.blue)),
            ],
          ),
        ),
        2000,
      ),
    );

    final redBox = tester.renderObject<RenderBox>(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == Colors.red,
      ),
    );
    // The Expanded section takes the leftover height (600 - 20) — not zero.
    expect(redBox.size.height, 580);
  });
}

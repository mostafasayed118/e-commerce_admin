import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

/// Centers page content and caps its width, so screens that are lists or
/// grids stop stretching edge-to-edge on wide windows/desktops.
///
/// Constraint-based (the house pattern): a plain [LayoutBuilder] + [SizedBox]
/// with no platform or device checks. Below [maxWidth] this is a no-op —
/// content behaves exactly as before — so wrapping a screen body is safe at
/// any viewport size.
///
/// The child receives a **tight** width (min of [maxWidth] and the available
/// width) and the full available height, so children built around
/// `Expanded`/`Column` (search fields, grids, dashboards) keep their
/// full-height behavior — a loose-width wrapper would collapse them to
/// intrinsic size and center them.
///
/// [maxWidth] defaults to [ResponsiveBreakpoints.contentMaxWidth]; forms
/// pass [ResponsiveBreakpoints.formMaxWidth].
class ContentMaxWidth extends StatelessWidget {
  const ContentMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

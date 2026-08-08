import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

/// Lays two panes side by side on wide surfaces and stacks them on narrow
/// ones — the two-pane counterpart to [ContentMaxWidth].
///
/// Wide: a [Row] with [left] and [right] split by [spacing]. Narrow: a
/// [Column] with [left] above [right] (the natural reading order for a
/// phone). Panes are [Expanded] in both modes, so callers just supply the
/// two blocks and get a sensible desktop split for free.
///
/// Used by product detail (image | info) and checkout (form | summary).
class ResponsiveTwoPane extends StatelessWidget {
  const ResponsiveTwoPane({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = ResponsiveBreakpoints.twoPane,
    this.spacing = 24,
  });

  final Widget left;
  final Widget right;

  /// The width at which the panes stop stacking and sit side by side.
  final double breakpoint;

  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;
        final panes = [left, right];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, pane) in panes.indexed) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: pane),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, pane) in panes.indexed) ...[
              if (i > 0) SizedBox(height: spacing),
              pane,
            ],
          ],
        );
      },
    );
  }
}

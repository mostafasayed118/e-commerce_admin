import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

/// Lays a row of form fields side by side on wide surfaces and stacks them
/// on narrow ones.
///
/// On wide surfaces each child is [Expanded] in a [Row] (so e.g. name +
/// phone share one line); on narrow surfaces the children stack in a
/// [Column] at full width. The [spacing] applies along the layout's main
/// axis, so a single value works for both modes.
///
/// Used by the shipping fields (name | phone) and the product pricing fields
/// (price | discount | stock).
class ResponsiveFormRow extends StatelessWidget {
  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.breakpoint = ResponsiveBreakpoints.formRow,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;

  /// The width at which the fields stop stacking and sit side by side.
  final double breakpoint;

  final double spacing;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;
        if (wide) {
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: child),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) SizedBox(height: spacing),
              child,
            ],
          ],
        );
      },
    );
  }
}

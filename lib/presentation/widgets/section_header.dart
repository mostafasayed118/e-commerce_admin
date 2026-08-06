import 'package:flutter/material.dart';

/// Uppercase section label used to group blocks inside a screen (dashboard
/// sections, order-detail sections). All-caps is a no-op for Arabic (no
/// letter case); the tracking is Latin-only too — spaced-out Arabic glyphs
/// look broken.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing:
                Directionality.of(context) == TextDirection.rtl ? 0 : 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

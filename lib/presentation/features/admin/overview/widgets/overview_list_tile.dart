import 'package:flutter/material.dart';

/// The shared dashboard-row scaffold: a contentless-padding [ListTile] with
/// a tonal [CircleAvatar] leading, a w600 title, and optional subtitle /
/// trailing / tap. Used by the overview's TopCouponTile, CouponUsageTile and
/// LowStockTile so the three rows stay visually aligned without re-declaring
/// the ListTile/CircleAvatar scaffolding in each file.
class OverviewListTile extends StatelessWidget {
  const OverviewListTile({
    super.key,
    required this.avatarBackground,
    required this.avatarForeground,
    required this.avatarIcon,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Color avatarBackground;
  final Color avatarForeground;
  final IconData avatarIcon;
  final String title;

  /// Overrides the default w600 [TextTheme.titleSmall] (LowStockTile uses
  /// the plain weight).
  final TextStyle? titleStyle;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: avatarBackground,
        foregroundColor: avatarForeground,
        child: Icon(avatarIcon, size: 20),
      ),
      title: Text(
        title,
        style:
            titleStyle ??
            theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

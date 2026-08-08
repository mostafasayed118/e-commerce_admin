import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_ext.dart';

/// One navigation destination for a shell.
class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// When non-null, the destination icon shows a Material 3 [Badge] with this
  /// count (hidden at 0) — e.g. the shop shell's cart item count.
  final int? badgeCount;
}

/// Responsive scaffold shared by the shop and admin shells.
///
/// **Constraint-based, not device-type based** (per the cross-cutting spec):
/// a `LayoutBuilder` measures the available width and picks
/// [NavigationRail] (wide: >= [wideBreakpoint]) or [NavigationBar]
/// (narrow), so the same code serves a phone, a tablet and a desktop window
/// without a single `Platform.` check.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.navigationShell,
    required this.destinations,
    this.exitAction,
  });

  /// Width at or above which the shell switches to the rail layout.
  static const double wideBreakpoint = 720;

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;

  /// Optional "leave this shell" action — e.g. the admin shell's way back to
  /// the customer view. Rendered as a trailing rail button (wide) or an extra
  /// bottom-bar entry (narrow); tapping it runs its `onTap` instead of
  /// switching branches. Null hides the affordance entirely (the shop shell
  /// passes nothing). Not visible on routes pushed over the shell (admin
  /// detail/form screens cover it) — those have their own back buttons.
  final ({IconData icon, String label, VoidCallback onTap})? exitAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  trailing: exitAction == null ? null : _railExit(context),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: _icon(context, d, d.icon),
                        selectedIcon: _icon(context, d, d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: _icon(context, d, d.icon),
                  selectedIcon: _icon(context, d, d.selectedIcon),
                  label: d.label,
                ),
              // The exit action is a bottom-bar entry on narrow layouts — the
              // bar has no trailing slot, so it becomes the last destination.
              if (exitAction case final action?)
                NavigationDestination(
                  icon: Icon(action.icon),
                  label: action.label,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _icon(BuildContext context, ShellDestination destination, IconData icon) {
    final count = destination.badgeCount ?? 0;
    return Badge(
      // The badge count follows the active locale's digits (like every
      // other number in the app).
      label: Text(context.localizeDigits('$count')),
      isLabelVisible: count > 0,
      child: Icon(icon),
    );
  }

  void _onDestinationSelected(int index) {
    // The extra bottom-bar entry (last index) is the exit action, not a
    // branch — tapping it leaves the shell instead of switching branches.
    final exit = exitAction;
    if (exit != null && index == destinations.length) {
      exit.onTap();
      return;
    }
    // Re-selecting the current branch resets it to its initial location —
    // the standard GoRouter pattern for "tap the tab again to go home".
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// The exit affordance pinned at the bottom of the rail: an icon button
  /// with its label, mirroring a destination's icon+label look. The label is
  /// also the IconButton's tooltip, so the semantic label needs no extra
  /// wrapper.
  Widget _railExit(BuildContext context) {
    final action = exitAction!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(action.icon),
            tooltip: action.label,
            onPressed: action.onTap,
          ),
          Text(
            action.label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

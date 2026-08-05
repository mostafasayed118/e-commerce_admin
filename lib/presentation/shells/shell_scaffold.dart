import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  });

  /// Width at or above which the shell switches to the rail layout.
  static const double wideBreakpoint = 720;

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;

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
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: _icon(d, d.icon),
                        selectedIcon: _icon(d, d.selectedIcon),
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
                  icon: _icon(d, d.icon),
                  selectedIcon: _icon(d, d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _icon(ShellDestination destination, IconData icon) {
    final count = destination.badgeCount ?? 0;
    return Badge(
      label: Text('$count'),
      isLabelVisible: count > 0,
      child: Icon(icon),
    );
  }

  void _onDestinationSelected(int index) {
    // Re-selecting the current branch resets it to its initial location —
    // the standard GoRouter pattern for "tap the tab again to go home".
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

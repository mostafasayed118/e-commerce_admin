import 'package:flutter/material.dart';

/// The admin shell's "create" [FloatingActionButton].
///
/// Every admin branch (Products, Categories, Coupons) shows an extended FAB
/// that creates its entity. They share more than looks — the admin shell
/// keeps every *visited* branch alive (StatefulShellRoute's IndexedStack),
/// so once two or more FAB-bearing branches are built, their FABs coexist in
/// the shell route's subtree. The forms and dialogs they open are pushed on
/// the **root navigator** (covering the shell), whose hero scan then sees
/// every kept-alive FAB at once. Each FAB therefore MUST carry a distinct
/// [heroTag] — the default FloatingActionButton tag would collide and throw
/// "multiple heroes share the same tag". [branch] feeds the stable, unique
/// tag (`admin-$branch-fab`); never reuse a branch value within the shell.
class AdminFab extends StatelessWidget {
  const AdminFab({
    super.key,
    required this.branch,
    required this.label,
    required this.onPressed,
  });

  /// The owning shell branch (e.g. `'products'`) — derives the unique
  /// [heroTag]. Must be unique within the admin shell.
  final String branch;

  /// The FAB's label (e.g. `l10n.newProduct`).
  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
      heroTag: 'admin-$branch-fab',
    );
  }
}

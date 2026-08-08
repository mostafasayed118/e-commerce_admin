import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n_ext.dart';

/// The storefront AppBar action on routes pushed over the admin shell:
/// jumps straight back to the customer view (`/`).
///
/// Complements the shell-level exit affordance (ShellScaffold's
/// `exitAction`), which pushed routes cover — an admin deep in an edit form
/// or order detail can leave without backing out first. Same keep-unlocked
/// semantics as the shell exit: it only navigates.
class AdminStorefrontAction extends StatelessWidget {
  const AdminStorefrontAction({super.key});

  /// Single source for the storefront affordance's icon — the shell-level
  /// exit (AdminShell's `exitAction`) uses the same [icon], so a change here
  /// stays in sync with the rail/bar entry.
  static const IconData icon = Icons.storefront_outlined;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(icon),
      tooltip: context.l10n.backToStore,
      onPressed: () => context.go('/'),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';

/// Shows a confirm dialog (Cancel / confirm) and resolves to true only when
/// the user confirms.
///
/// Shared by the admin branches that delete entities (Products, Categories,
/// Coupons — where the button reads "Delete" via the default) and the cart's
/// clear-all (which passes its own "Clear" label). The button labels are
/// resolved inside the builder so they always follow the active locale.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          // Null resolves to the localized default inside the builder (a
          // default parameter cannot read context).
          child: Text(confirmLabel ?? context.l10n.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

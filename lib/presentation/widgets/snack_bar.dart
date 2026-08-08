import 'package:flutter/material.dart';

import '../../core/error/app_error.dart';
import '../l10n/l10n_ext.dart';

/// The app's snackbar helpers — a failure toast and a success toast — used
/// across the admin and shop screens. Centralizing them keeps snackbar
/// presentation consistent and locale-aware (including Eastern Arabic
/// digits in parameterized messages).
void showErrorSnackBar(BuildContext context, AppError error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.errorText(error))),
  );
}

/// The success toast companion to [showErrorSnackBar]: a plain message in
/// a SnackBar, used by the "added to cart / wishlist / marked as" toasts.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

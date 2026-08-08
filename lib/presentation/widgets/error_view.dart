import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import 'message_view.dart';

/// The app-wide failure view — the shared `Icons.error_outline` block every
/// screen's error state showed.
///
/// Defaults to the generic "Something went wrong" / "Couldn't load" pair;
/// detail screens pass their own title (`couldNotLoadProduct`,
/// `couldNotLoadOrder`). Reads its own l10n keys, so call sites stay a
/// one-liner. Error states that need a different icon or message (not-found
/// views, empty states) still use [MessageView] directly.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.title, this.message});

  /// Overrides the generic "Something went wrong" title.
  final String? title;

  /// Overrides the generic "Couldn't load" message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MessageView(
      icon: Icons.error_outline,
      // The generic pair only applies when no custom title was given:
      // detail screens that pass their own title (couldNotLoadX) keep the
      // title-only shape they always had, without a redundant default line.
      title: title ?? l10n.somethingWentWrong,
      message: message ?? (title == null ? l10n.errorLoadFailed : null),
    );
  }
}

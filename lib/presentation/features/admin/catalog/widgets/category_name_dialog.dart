import 'package:flutter/material.dart';

import '../../../../l10n/l10n_ext.dart';

/// The add/rename category dialog: an English name (required) and an Arabic
/// name (optional — blank is stored as null so the UI falls back to English).
///
/// Owns its text controllers so they are disposed with the dialog (a
/// controller created ad-hoc in a method would never be disposed).
class CategoryNameDialog extends StatefulWidget {
  const CategoryNameDialog({
    super.key,
    required this.title,
    required this.initial,
    this.initialAr,
    required this.confirmLabel,
  });

  final String title;
  final String initial;
  final String? initialAr;
  final String confirmLabel;

  @override
  State<CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<CategoryNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  late final TextEditingController _controllerAr =
      TextEditingController(text: widget.initialAr ?? '');

  @override
  void dispose() {
    _controller.dispose();
    _controllerAr.dispose();
    super.dispose();
  }

  /// Pops the entered names; the English name is required, the Arabic one
  /// optional.
  void _submit() => Navigator.pop(
        context,
        (
          name: _controller.text.trim(),
          nameAr: emptyToNull(_controllerAr.text),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('category-name-field'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: context.l10n.categoryName,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('category-name-ar-field'),
            controller: _controllerAr,
            decoration: InputDecoration(
              labelText: context.l10n.arabicNameOptional,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

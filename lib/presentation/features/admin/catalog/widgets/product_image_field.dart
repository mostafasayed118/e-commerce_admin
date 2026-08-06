import 'package:flutter/material.dart';

import '../../../../l10n/l10n_ext.dart';
import '../../../catalog/widgets/product_image.dart';

/// The product form's image section: preview thumb + pick/replace and remove
/// actions. Purely presentational — the file-picking and cleanup logic stays
/// in the form's state (it cannot run in the widget-test harness).
class ProductImageField extends StatelessWidget {
  const ProductImageField({
    super.key,
    required this.imagePath,
    required this.picking,
    required this.onPick,
    required this.onRemove,
  });

  final String? imagePath;
  final bool picking;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 96,
            child: ProductImage(imagePath: imagePath, iconSize: 36),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: picking ? null : onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  imagePath == null ? l10n.addImage : l10n.replaceImage,
                ),
              ),
              if (imagePath != null)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.removeImage),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

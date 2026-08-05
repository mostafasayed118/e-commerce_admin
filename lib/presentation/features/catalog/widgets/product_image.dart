import 'package:flutter/material.dart';

/// Product image placeholder.
///
/// The seed data ships with no images, so today every product renders this
/// tonal placeholder. Real file loading (path_provider + image_picker) lands
/// with Task 14, when admin-uploaded images start to exist; this widget is
/// where that implementation goes.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.iconSize = 40});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

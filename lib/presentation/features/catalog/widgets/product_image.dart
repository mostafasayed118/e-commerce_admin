import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../data/services/image_store.dart';

/// Product image: renders the stored file for [imagePath] (a relative path in
/// the app documents dir, resolved via [ImageStore]) and falls back to a
/// tonal placeholder when there is no image or the file is missing.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.imagePath, this.iconSize = 40});

  final String? imagePath;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) return _Placeholder(iconSize: iconSize);
    return FutureBuilder<File>(
      future: getIt<ImageStore>().fileFor(imagePath!),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null && file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
        return _Placeholder(iconSize: iconSize);
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.iconSize});

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

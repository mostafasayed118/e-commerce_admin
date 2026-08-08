import 'package:flutter/material.dart';

/// A row of five star icons: [rating] of them filled, the rest outlined.
/// Shared by the storefront review tile and the admin moderation list so the
/// rating rendering stays visually consistent (and isn't duplicated).
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  /// 1-5 filled stars.
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: size,
            color: i <= rating ? Colors.amber : scheme.outlineVariant,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/entities/category.dart';
import '../../../l10n/l10n_ext.dart';

/// The horizontal "All + categories" filter chip row. Directional padding so
/// the gap flips to the leading edge in RTL (Task 23).
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            context,
            label: context.l10n.all,
            selected: selectedCategoryId == null,
            value: null,
          ),
          for (final category in categories)
            _chip(
              context,
              label: context.categoryName(category),
              selected: selectedCategoryId == category.id,
              value: category.id,
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required int? value,
  }) {
    return Padding(
      // Directional so the gap flips to the leading edge in RTL (Task 23).
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
        showCheckmark: false,
      ),
    );
  }
}

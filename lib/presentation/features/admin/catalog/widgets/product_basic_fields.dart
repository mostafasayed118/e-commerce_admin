import 'package:flutter/material.dart';

import '../../../../../core/entities/category.dart';
import '../../../../l10n/l10n_ext.dart';

/// The product form's identity section: canonical English name (required),
/// optional Arabic name, and the category dropdown. Controllers and the
/// name validator are owned by the form's state and passed in.
class ProductBasicFields extends StatelessWidget {
  const ProductBasicFields({
    super.key,
    required this.nameController,
    required this.nameArController,
    required this.categories,
    required this.categoryId,
    required this.onCategoryChanged,
    required this.nameValidator,
  });

  final TextEditingController nameController;
  final TextEditingController nameArController;
  final List<Category> categories;
  final int? categoryId;
  final ValueChanged<int?> onCategoryChanged;
  final FormFieldValidator<String> nameValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('product-name'),
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.name,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          validator: nameValidator,
        ),
        const SizedBox(height: 16),
        // Optional localized content (Task 23 follow-up): the canonical
        // English field above, with an Arabic variant below. Left empty,
        // the product renders its English text in Arabic mode too.
        TextFormField(
          key: const Key('product-name-ar'),
          controller: nameArController,
          decoration: InputDecoration(
            labelText: l10n.arabicNameOptional,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: const Key('product-category'),
          initialValue: categoryId,
          decoration: InputDecoration(
            labelText: l10n.category,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final category in categories)
              DropdownMenuItem(
                value: category.id,
                child: Text(context.categoryName(category)),
              ),
          ],
          onChanged: onCategoryChanged,
          validator: (value) => value == null ? l10n.chooseCategory : null,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/entities/category.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../../widgets/message_view.dart';
import '../admin_catalog_state.dart';

/// The category list with per-row rename / delete actions. Rename and delete
/// are delegated to the screen via callbacks (the screen owns the dialogs and
/// the cubit calls).
class CategoryList extends StatelessWidget {
  const CategoryList({
    super.key,
    required this.state,
    required this.onRename,
    required this.onDelete,
  });

  final AdminCatalogLoaded state;
  final ValueChanged<Category> onRename;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.categories.isEmpty) {
      return MessageView(
        icon: Icons.category_outlined,
        title: l10n.noCategoriesTitle,
        message: l10n.noCategoriesMessage,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final category = state.categories[index];
        final productCount =
            state.products.where((p) => p.categoryId == category.id).length;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(context.categoryName(category).isEmpty
                ? '?'
                : context.categoryName(category)[0]),
          ),
          title: Text(context.categoryName(category)),
          subtitle: Text(context.localizeDigits(l10n.productCount(productCount))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.renameTooltip(context.categoryName(category)),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => onRename(category),
              ),
              IconButton(
                tooltip: l10n.deleteCategoryTooltip(context.categoryName(category)),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(category),
              ),
            ],
          ),
        );
      },
    );
  }
}

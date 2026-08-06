import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/category.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/message_view.dart';
import 'admin_catalog_cubit.dart';
import 'widgets/category_list.dart';
import 'widgets/category_name_dialog.dart';

/// Admin category management: add / rename / delete, with the data layer's
/// delete-blocked rule surfacing as a SnackBar (a category still referenced
/// by products cannot be deleted — spec A4). The name dialog and the list
/// live in `widgets/`.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCatalogCubit>.value(
      value: getIt<AdminCatalogCubit>(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  /// Collects the English (required) and Arabic (optional) names; the dialog
  /// pops a record and nothing happens if the English name is blank.
  Future<void> _promptForName(
    BuildContext context, {
    required String title,
    String initial = '',
    String? initialAr,
    String? confirmLabel,
    required Future<void> Function(String name, String? nameAr) onSubmit,
  }) async {
    final result = await showDialog<({String name, String? nameAr})>(
      context: context,
      builder: (context) => CategoryNameDialog(
        title: title,
        initial: initial,
        initialAr: initialAr,
        // Null resolves to the localized default inside the dialog (a
        // default parameter cannot read context).
        confirmLabel: confirmLabel ?? context.l10n.save,
      ),
    );
    if (result == null || result.name.isEmpty || !context.mounted) return;
    await onSubmit(result.name, result.nameAr);
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle(context.categoryName(category))),
        content: Text(l10n.deleteCategoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await context.read<AdminCatalogCubit>().deleteCategory(
          category.id,
        );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      // The blocked rule (products still reference it) or other failures land
      // here as a localized message.
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.errorText(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminCatalogCubit>();
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _promptForName(
          context,
          title: l10n.newCategory,
          confirmLabel: l10n.create,
          onSubmit: (name, nameAr) async {
            final result = await cubit.createCategory(name, nameAr: nameAr);
            if (!context.mounted) return;
            result.fold(
              onSuccess: (_) {},
              onFailure: (error) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.errorText(error))),
              ),
            );
          },
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCategory),
      ),
      body: BlocBuilder<AdminCatalogCubit, AdminCatalogState>(
        builder: (context, state) => switch (state) {
          AdminCatalogLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminCatalogError() => MessageView(
              icon: Icons.error_outline,
              title: l10n.somethingWentWrong,
              message: l10n.errorLoadFailed,
            ),
          AdminCatalogLoaded() => CategoryList(
              state: state,
              onRename: (category) => _promptForName(
                context,
                title: l10n.renameCategory,
                initial: category.name,
                initialAr: category.nameAr,
                onSubmit: (name, nameAr) async {
                  final result = await cubit.updateCategory(
                    category.copyWith(name: name, nameAr: nameAr),
                  );
                  if (!context.mounted) return;
                  result.fold(
                    onSuccess: (_) {},
                    onFailure: (error) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.errorText(error))),
                        ),
                  );
                },
              ),
              onDelete: (category) => _confirmDelete(context, category),
            ),
        },
      ),
    );
  }
}

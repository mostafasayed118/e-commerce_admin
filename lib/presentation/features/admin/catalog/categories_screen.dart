import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/category.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/message_view.dart';
import 'admin_catalog_cubit.dart';

/// Admin category management: add / rename / delete, with the data layer's
/// delete-blocked rule surfacing as a SnackBar (a category still referenced
/// by products cannot be deleted — spec A4).
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
      builder: (context) => _NameDialog(
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
          AdminCatalogLoaded() => _CategoryList(
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

/// Owns its text controller so it is disposed with the dialog (a controller
/// created ad-hoc in a method would never be disposed).
class _NameDialog extends StatefulWidget {
  const _NameDialog({
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
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
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

  /// The English name is required; the Arabic name is optional (blank is
  /// stored as null so the UI falls back to English).
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

class _CategoryList extends StatelessWidget {
  const _CategoryList({
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
          subtitle: Text(l10n.productCount(productCount)),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/category.dart';
import '../../../../core/error/result.dart';
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

  Future<void> _promptForName(
    BuildContext context, {
    required String title,
    String initial = '',
    String confirmLabel = 'Save',
    required Future<void> Function(String name) onSubmit,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(
        title: title,
        initial: initial,
        confirmLabel: confirmLabel,
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await onSubmit(name);
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text(
          'Categories that still have products cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
      // here as a readable message.
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminCatalogCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _promptForName(
          context,
          title: 'New category',
          confirmLabel: 'Create',
          onSubmit: (name) async {
            final result = await cubit.createCategory(name);
            if (!context.mounted) return;
            result.fold(
              onSuccess: (_) {},
              onFailure: (error) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.message)),
              ),
            );
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('New category'),
      ),
      body: BlocBuilder<AdminCatalogCubit, AdminCatalogState>(
        builder: (context, state) => switch (state) {
          AdminCatalogLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminCatalogError(:final message) => MessageView(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: message,
            ),
          AdminCatalogLoaded() => _CategoryList(
              state: state,
              onRename: (category) => _promptForName(
                context,
                title: 'Rename category',
                initial: category.name,
                onSubmit: (name) async {
                  final result = await cubit.updateCategory(
                    category.copyWith(name: name),
                  );
                  if (!context.mounted) return;
                  result.fold(
                    onSuccess: (_) {},
                    onFailure: (error) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.message)),
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
    required this.confirmLabel,
  });

  final String title;
  final String initial;
  final String confirmLabel;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('category-name-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Category name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
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
    if (state.categories.isEmpty) {
      return const MessageView(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        message: 'Create a category before adding products.',
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
            child: Text(category.name.isEmpty ? '?' : category.name[0]),
          ),
          title: Text(category.name),
          subtitle: Text(
            '$productCount product${productCount == 1 ? '' : 's'}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Rename ${category.name}',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => onRename(category),
              ),
              IconButton(
                tooltip: 'Delete ${category.name}',
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

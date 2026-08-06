import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/message_view.dart';
import 'admin_catalog_cubit.dart';
import 'widgets/product_list.dart';

/// Admin product management: list with stock badges, create (FAB), edit
/// (tap row), delete (confirm dialog). The DI-registered [AdminCatalogCubit]
/// is provided by **value** — DI owns its lifecycle (same rule as
/// CatalogScreen), so this never closes it. The list itself lives in
/// [ProductList] (`widgets/`), which stays presentational: navigation and
/// the delete flow are orchestrated here.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCatalogCubit>.value(
      value: getIt<AdminCatalogCubit>(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProductTitle),
        content: Text(l10n.deleteProductMessage(context.productName(product))),
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

    final result = await context.read<AdminCatalogCubit>().deleteProduct(
          product.id,
        );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      // Success is silent — the watch stream re-emits the shorter list.
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.errorText(error))),
        );
      },
    );
  }

  void _openNewProduct(BuildContext context) => context.push('/admin/products/new');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewProduct(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newProduct),
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
          AdminCatalogLoaded() => ProductList(
              state: state,
              onEdit: (product) => context.push('/admin/products/${product.id}/edit'),
              onDelete: (product) => _confirmDelete(context, product),
              onCreate: () => _openNewProduct(context),
            ),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/snack_bar.dart';
import '../widgets/admin_fab.dart';
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
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteProductTitle,
      message: l10n.deleteProductMessage(context.productName(product)),
    );
    if (!confirmed || !context.mounted) return;

    final result = await context.read<AdminCatalogCubit>().deleteProduct(
          product.id,
        );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      // Success is silent — the watch stream re-emits the shorter list.
      onFailure: (error) => showErrorSnackBar(context, error),
    );
  }

  void _openNewProduct(BuildContext context) => context.push('/admin/products/new');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsTitle)),
      floatingActionButton: AdminFab(
        branch: 'products',
        label: l10n.newProduct,
        onPressed: () => _openNewProduct(context),
      ),
      body: BlocBuilder<AdminCatalogCubit, AdminCatalogState>(
        builder: (context, state) => switch (state) {
          AdminCatalogLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminCatalogError() => const ErrorView(),
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

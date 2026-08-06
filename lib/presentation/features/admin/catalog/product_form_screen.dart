import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/message_view.dart';
import 'admin_catalog_cubit.dart';
import 'widgets/product_form.dart';

/// Admin create/edit screen for a product. Pushed on the root navigator by
/// ProductsScreen. Reads the product snapshot from the shared
/// [AdminCatalogCubit]'s loaded state — deep links to an unknown id resolve
/// to a "Product not found" view — then delegates the form to [ProductForm]
/// (`widgets/`).
class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key, this.productId});

  /// `null` → create mode; otherwise the id of the product being edited.
  final int? productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCatalogCubit>.value(
      value: getIt<AdminCatalogCubit>(),
      child: BlocBuilder<AdminCatalogCubit, AdminCatalogState>(
        // Every state is handled explicitly — an error shows the message
        // instead of an infinite spinner (cold deep link + stream failure).
        builder: (context, state) => switch (state) {
          AdminCatalogLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          AdminCatalogError() => Scaffold(
              body: MessageView(
                icon: Icons.error_outline,
                title: context.l10n.somethingWentWrong,
                message: context.l10n.errorLoadFailed,
              ),
            ),
          AdminCatalogLoaded() => _buildForm(context, state),
        },
      ),
    );
  }

  /// Resolves the edited product from the loaded state and builds the form.
  /// A cold deep link to an unknown id resolves to a not-found view.
  Widget _buildForm(BuildContext context, AdminCatalogLoaded state) {
    final product = productId == null
        ? null
        : state.products.where((p) => p.id == productId).firstOrNull;
    if (productId != null && product == null) {
      return Scaffold(
        body: MessageView(
          icon: Icons.search_off,
          title: context.l10n.productNotFound,
          message: context.l10n.productRemovedFromCatalog,
        ),
      );
    }
    return ProductForm(
      product: product,
      categories: state.categories,
    );
  }
}

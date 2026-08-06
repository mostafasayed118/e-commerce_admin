import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/product.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/usecases/cart/add_to_cart.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/message_view.dart';
import 'widgets/product_image.dart';

/// Product detail: reactive product via [ProductRepository.watchProductById]
/// (so stock changes from the admin side reflect live), plus Add to Cart
/// wired through the [AddToCart] use case (Task 10) — the full stack, first
/// time in the UI.
///
/// Deliberately no dedicated Cubit: one read stream + one action does not
/// justify a state machine (Section C.3); the catalog feature's Cubit is
/// [CatalogCubit].
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _adding = false;

  Future<void> _addToCart(Product product) async {
    setState(() => _adding = true);
    final result = await getIt<AddToCart>()(product.id);
    if (!mounted) return;
    setState(() => _adding = false);
    final messenger = ScaffoldMessenger.of(context);
    result.fold(
      onSuccess: (_) => messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.addedToCart(context.productName(product)))),
      ),
      onFailure: (error) => messenger.showSnackBar(
        SnackBar(content: Text(context.errorText(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productTitle)),
      body: StreamBuilder<Product?>(
        stream: getIt<ProductRepository>().watchProductById(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MessageView(
              icon: Icons.error_outline,
              title: l10n.couldNotLoadProduct,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snapshot.data;
          if (product == null) {
            return MessageView(
              icon: Icons.search_off,
              title: l10n.productNotFound,
            );
          }
          return _ProductDetailBody(
            product: product,
            adding: _adding,
            onAddToCart: () => _addToCart(product),
          );
        },
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({
    required this.product,
    required this.adding,
    required this.onAddToCart,
  });

  final Product product;
  final bool adding;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final outOfStock = product.isOutOfStock;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: ProductImage(iconSize: 64),
          ),
        ),
        const SizedBox(height: 20),
        Text(context.productName(product), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              context.formatCents(product.finalPriceCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (product.hasDiscount) ...[
              const SizedBox(width: 8),
              Text(
                context.formatCents(product.priceCents),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-${product.discountPercent}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (outOfStock)
          Text(
            l10n.outOfStock,
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.error),
          )
        else if (product.isLowStock)
          Text(
            l10n.lowStockLeft(product.stock),
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.error),
          )
        else
          Text(
            l10n.inStock,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.primary,
            ),
          ),
        const SizedBox(height: 20),
        Text(
          context.productDescription(product).isEmpty
              ? l10n.noDescription
              : context.productDescription(product),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: (outOfStock || adding) ? null : onAddToCart,
          icon: adding
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_shopping_cart),
          label: Text(
            outOfStock
                ? l10n.outOfStock
                : (adding ? l10n.adding : l10n.addToCart),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

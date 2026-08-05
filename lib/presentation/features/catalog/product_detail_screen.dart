import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/product.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/money.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/usecases/cart/add_to_cart.dart';
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
        SnackBar(content: Text('${product.name} added to cart')),
      ),
      onFailure: (error) => messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: StreamBuilder<Product?>(
        stream: getIt<ProductRepository>().watchProductById(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const MessageView(
              icon: Icons.error_outline,
              title: 'Could not load product',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snapshot.data;
          if (product == null) {
            return const MessageView(
              icon: Icons.search_off,
              title: 'Product not found',
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
        Text(product.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatCents(product.finalPriceCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (product.hasDiscount) ...[
              const SizedBox(width: 8),
              Text(
                formatCents(product.priceCents),
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
            'Out of stock',
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.error),
          )
        else if (product.isLowStock)
          Text(
            'Low stock: ${product.stock} left',
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.error),
          )
        else
          Text(
            'In stock',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.primary,
            ),
          ),
        const SizedBox(height: 20),
        Text(
          product.description.isEmpty
              ? 'No description available.'
              : product.description,
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
                ? 'Out of stock'
                : (adding ? 'Adding…' : 'Add to Cart'),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

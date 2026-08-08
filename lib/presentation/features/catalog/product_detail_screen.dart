import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/product.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/usecases/cart/add_to_cart.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/error_view.dart';
import '../../widgets/message_view.dart';
import '../../widgets/responsive/content_max_width.dart';
import '../../widgets/responsive/responsive_two_pane.dart';
import '../../widgets/snack_bar.dart';
import '../wishlist/widgets/wishlist_heart.dart';
import 'widgets/product_image.dart';
import 'widgets/product_price_row.dart';
import 'widgets/reviews_section.dart';
import 'widgets/stock_status_label.dart';

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
    result.fold(
      onSuccess: (_) => showSuccessSnackBar(
        context,
        context.l10n.addedToCart(context.productName(product)),
      ),
      onFailure: (error) => showErrorSnackBar(context, error),
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
            return ErrorView(title: l10n.couldNotLoadProduct);
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

    // The image and the info read as two columns on wide surfaces (image |
    // info, product-detail convention) and stack naturally on phones — the
    // ResponsiveTwoPane handles both. The reviews stay full-width below.
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.4,
        child: ProductImage(iconSize: 64),
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.productName(product), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        // Flexible so the price row can never overflow: the struck price
        // stays whole and the badge ellipsizes (same contract as the card's
        // price row — Arabic digits + bidi marks are wider).
        ProductPriceRow(
          product: product,
          baseline: true,
          gap: 8,
          showDiscountBadge: true,
          finalPriceStyle: theme.textTheme.headlineMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // The detail screen shows a stock line in every state.
        StockStatusLabel(
          product: product,
          style: theme.textTheme.titleSmall,
          showInStock: true,
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
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
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
            ),
            const SizedBox(width: 12),
            // The wishlist heart beside the CTA — same tonal style.
            WishlistHeartButton(product: product),
          ],
        ),
      ],
    );

    return ContentMaxWidth(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ResponsiveTwoPane(left: image, right: info),
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Approved customer reviews (moderated: hidden reviews never reach
          // the storefront read stream) + the write-review dialog.
          ReviewsSection(productId: product.id),
        ],
      ),
    );
  }
}

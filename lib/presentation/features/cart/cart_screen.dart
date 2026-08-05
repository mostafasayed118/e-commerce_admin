import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/money.dart';
import '../../widgets/message_view.dart';
import '../catalog/widgets/product_image.dart';
import 'cart_cubit.dart';

/// The customer cart: line list with quantity steppers, remove, clear-all,
/// and a live totals bar (subtotal / savings / total, integer-cents math).
/// DI-owned [CartCubit] provided by **value** (same lifecycle rule as every
/// other feature screen).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CartCubit>.value(
      value: getIt<CartCubit>(),
      child: const _CartView(),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('Every item will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<CartCubit>().clear();
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      onFailure: (error) => _showError(context, error),
    );
  }

  void _showError(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A single Scaffold for every state — the clear action belongs on the
    // one AppBar, shown only while the cart has lines.
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final filled = state is CartLoaded && state.lines.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cart'),
            actions: [
              if (filled)
                IconButton(
                  tooltip: 'Clear cart',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _confirmClear(context),
                ),
            ],
          ),
          body: switch (state) {
            CartLoading() => const Center(child: CircularProgressIndicator()),
            CartError(:final message) => MessageView(
                icon: Icons.error_outline,
                title: 'Something went wrong',
                message: message,
              ),
            CartLoaded() => state.lines.isEmpty
                ? const _EmptyCart()
                : _FilledCart(state: state),
          },
        );
      },
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      message: 'Add something you like from the catalog.',
      action: FilledButton.tonalIcon(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.storefront_outlined),
        label: const Text('Browse products'),
      ),
    );
  }
}

class _FilledCart extends StatelessWidget {
  const _FilledCart({required this.state});

  final CartLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.lines.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final line = state.lines[index];
              return _CartLineTile(
                line: line,
                onAdd: () async {
                  final result = await cubit.updateQuantity(
                    line.product.id,
                    line.quantity + 1,
                  );
                  if (context.mounted) {
                    result.fold(
                      onSuccess: (_) {},
                      onFailure: (error) =>
                          _showCartError(context, error),
                    );
                  }
                },
                // At quantity 1, stepping down removes the line entirely —
                // the stepper is the only removal affordance per line.
                onRemoveOne: () async {
                  final result = line.quantity == 1
                      ? await cubit.removeItem(line.product.id)
                      : await cubit.updateQuantity(
                          line.product.id,
                          line.quantity - 1,
                        );
                  if (context.mounted) {
                    result.fold(
                      onSuccess: (_) {},
                      onFailure: (error) =>
                          _showCartError(context, error),
                    );
                  }
                },
              );
            },
          ),
        ),
        _TotalsBar(
          subtotalCents: state.subtotalCents,
          discountCents: state.discountCents,
          totalCents: state.totalCents,
          onCheckout: () => context.push('/checkout'),
        ),
      ],
    );
  }

  void _showCartError(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.onAdd,
    required this.onRemoveOne,
  });

  final CartLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemoveOne;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final product = line.product;
    final canAdd = !line.exceedsStock;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ProductImage(imagePath: product.imagePath, iconSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                // The struck-through original price is Flexible so a tight
                // name column ellipsizes it instead of overflowing.
                Row(
                  children: [
                    Text(
                      formatCents(product.finalPriceCents),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          formatCents(product.priceCents),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (line.exceedsStock) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Only ${product.stock} left in stock',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCents(line.lineTotalCents),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Remove one',
                    icon: const Icon(Icons.remove_circle_outline),
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemoveOne,
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${line.quantity}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add one',
                    icon: const Icon(Icons.add_circle_outline),
                    visualDensity: VisualDensity.compact,
                    onPressed: canAdd ? onAdd : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
    required this.onCheckout,
  });

  final int subtotalCents;
  final int discountCents;
  final int totalCents;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Subtotal', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(
                  formatCents(subtotalCents),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (discountCents > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Savings', style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    '-${formatCents(discountCents)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  formatCents(totalCents),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onCheckout,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

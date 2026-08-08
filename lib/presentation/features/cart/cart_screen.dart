import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/result.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/error_view.dart';
import '../../widgets/snack_bar.dart';
import 'cart_cubit.dart';
import 'widgets/cart_empty_view.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/cart_totals_bar.dart';

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
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.clearCartTitle,
      message: l10n.clearCartMessage,
      confirmLabel: l10n.clear,
    );
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<CartCubit>().clear();
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      onFailure: (error) => showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A single Scaffold for every state — the clear action belongs on the
    // one AppBar, shown only while the cart has lines.
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final filled = state is CartLoaded && state.lines.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.cartTitle),
            actions: [
              if (filled)
                IconButton(
                  tooltip: l10n.clearCart,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _confirmClear(context),
                ),
            ],
          ),
          body: switch (state) {
            CartLoading() => const Center(child: CircularProgressIndicator()),
            CartError() => const ErrorView(),
            CartLoaded() => state.lines.isEmpty
                ? const CartEmptyView()
                : _FilledCart(state: state),
          },
        );
      },
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
              return CartLineTile(
                line: line,
                onAdd: () async {
                  final result = await cubit.updateQuantity(
                    line.product.id,
                    line.quantity + 1,
                  );
                  if (context.mounted) {
                    result.fold(
                      onSuccess: (_) {},
                      onFailure: (error) => showErrorSnackBar(context, error),
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
                      onFailure: (error) => showErrorSnackBar(context, error),
                    );
                  }
                },
              );
            },
          ),
        ),
        CartTotalsBar(
          subtotalCents: state.subtotalCents,
          discountCents: state.discountCents,
          totalCents: state.totalCents,
          onCheckout: () => context.push('/checkout'),
        ),
      ],
    );
  }
}

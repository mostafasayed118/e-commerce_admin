import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/repositories/order_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/message_view.dart';
import '../../../widgets/snack_bar.dart';
import '../../orders/order_detail_view.dart';
import '../../orders/receipt_export_action.dart';
import '../../orders/status_visuals.dart';
import '../widgets/admin_storefront_action.dart';
import 'admin_orders_cubit.dart';

/// Admin order detail: the shared [OrderDetailView] plus a status action bar
/// that offers exactly the **legal** transitions for the current status
/// (`OrderStatus.canTransitionTo`). The repository remains the enforcement
/// boundary — this UI merely shows the moves that are allowed. The watch
/// stream re-emits the updated aggregate, so the chip, timeline and buttons
/// all refresh together after a successful transition.
class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  bool _updating = false;

  Future<void> _updateStatus(Order order, OrderStatus next) async {
    setState(() => _updating = true);
    final result = await getIt<AdminOrdersCubit>().updateStatus(
      order.id,
      next,
    );
    if (!mounted) return;
    setState(() => _updating = false);

    result.fold(
      onSuccess: (updated) => showSuccessSnackBar(
        context,
        context.l10n.markedAs(
          updated.orderNumber,
          orderStatusLabel(context, next),
        ),
      ),
      onFailure: (error) => showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StreamBuilder<Order?>(
      stream: getIt<OrderRepository>().watchOrderById(widget.orderId),
      builder: (context, snapshot) {
        final order = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.orderTitle),
            actions: [
              const AdminStorefrontAction(),
              // Receipt export (the same shared action the customer screen
              // uses), gated on the live stream so it is inert while
              // loading/erroring or when the order is gone.
              if (order != null) ReceiptExportAction(order: order),
            ],
          ),
          body: snapshot.hasError
              ? ErrorView(title: l10n.couldNotLoadOrder)
              : snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : order == null
                      ? MessageView(
                          icon: Icons.search_off,
                          title: l10n.orderNotFound,
                          message: l10n.orderRemoved,
                        )
                      : OrderDetailView(
                          order: order,
                          actions: _StatusActions(
                            order: order,
                            updating: _updating,
                            onUpdate: (next) => _updateStatus(order, next),
                          ),
                        ),
        );
      },
    );
  }
}

/// The action bar: legal transitions for the current status as buttons.
/// Terminal orders (delivered/cancelled) render a note instead.
class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.order,
    required this.updating,
    required this.onUpdate,
  });

  final Order order;
  final bool updating;
  final ValueChanged<OrderStatus> onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final legalTargets =
        OrderStatus.values.where(order.status.canTransitionTo).toList();
    if (legalTargets.isEmpty) {
      return Text(
        order.status.isTerminal
            // toLowerCase() is the English "sentence case" shape the original
            // used; it is a no-op for Arabic (no letter case).
            ? l10n.orderTerminalNote(
                orderStatusLabel(context, order.status).toLowerCase(),
              )
            : l10n.noFurtherActions,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actions,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            // Latin-only tracking — spaced-out Arabic glyphs look broken.
            letterSpacing:
                Directionality.of(context) == TextDirection.rtl ? 0 : 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final target in legalTargets)
              target == OrderStatus.cancelled
                  ? OutlinedButton.icon(
                      onPressed: updating ? null : () => onUpdate(target),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(l10n.cancelOrder),
                    )
                  : FilledButton.icon(
                      onPressed: updating ? null : () => onUpdate(target),
                      icon: Icon(_forwardIcon(target), size: 18),
                      label: Text(
                        l10n.markAs(
                          orderStatusLabel(context, target).toLowerCase(),
                        ),
                      ),
                    ),
          ],
        ),
      ],
    );
  }

  IconData _forwardIcon(OrderStatus target) => switch (target) {
        OrderStatus.confirmed => Icons.check,
        OrderStatus.shipped => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.check_circle_outline,
        OrderStatus.cancelled => Icons.cancel_outlined,
        // Never a legal transition target (canTransitionTo never returns it)
        // — kept only for switch exhaustiveness.
        OrderStatus.pending => Icons.schedule,
      };
}

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/repositories/order_repository.dart';
import '../../../widgets/message_view.dart';
import '../../orders/order_detail_view.dart';
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

    final messenger = ScaffoldMessenger.of(context);
    result.fold(
      onSuccess: (updated) => messenger.showSnackBar(
        SnackBar(content: Text('${updated.orderNumber} marked as ${next.label}')),
      ),
      onFailure: (error) => messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: StreamBuilder<Order?>(
        stream: getIt<OrderRepository>().watchOrderById(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const MessageView(
              icon: Icons.error_outline,
              title: 'Could not load order',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return const MessageView(
              icon: Icons.search_off,
              title: 'Order not found',
              message: 'This order may have been removed.',
            );
          }
          return OrderDetailView(
            order: order,
            actions: _StatusActions(
              order: order,
              updating: _updating,
              onUpdate: (next) => _updateStatus(order, next),
            ),
          );
        },
      ),
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

    final legalTargets =
        OrderStatus.values.where(order.status.canTransitionTo).toList();
    if (legalTargets.isEmpty) {
      return Text(
        order.status.isTerminal
            ? 'This order is ${order.status.label.toLowerCase()} — no further actions.'
            : 'No further actions available.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
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
                      label: const Text('Cancel order'),
                    )
                  : FilledButton.icon(
                      onPressed: updating ? null : () => onUpdate(target),
                      icon: Icon(_forwardIcon(target), size: 18),
                      label: Text('Mark ${target.label.toLowerCase()}'),
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

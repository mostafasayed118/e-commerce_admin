import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../core/utils/money.dart';
import '../../widgets/message_view.dart';
import 'order_date_format.dart';
import 'orders_cubit.dart';
import 'status_visuals.dart';

/// The customer's order history. Reactive via [OrdersCubit]; each tile opens
/// the detail screen with the full timeline. DI-owned cubit provided by
/// **value** (the lifecycle rule that never closes a shared instance).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>.value(
      value: getIt<OrdersCubit>(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) => switch (state) {
          OrdersLoading() => const Center(child: CircularProgressIndicator()),
          OrdersError(:final message) => MessageView(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: message,
            ),
          OrdersLoaded(:final orders) => orders.isEmpty
              ? const _EmptyOrders()
              : _OrderList(orders: orders),
        },
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.receipt_long_outlined,
      title: 'No orders yet',
      message: 'Your order history will appear here after your first checkout.',
      action: FilledButton.tonalIcon(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.storefront_outlined),
        label: const Text('Browse products'),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final order = orders[index];
        final visuals = orderStatusVisuals(order.status, scheme);
        // The date part is omitted when absent rather than fabricated — a
        // made-up timestamp would be a lie on the history screen.
        final subtitleParts = [
          if (order.createdAt != null) formatOrderDate(order.createdAt!),
          '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
          formatCents(order.totalCents),
        ];
        return ListTile(
          onTap: () => context.push('/orders/${order.id}'),
          leading: CircleAvatar(
            backgroundColor: visuals.background,
            foregroundColor: visuals.color,
            child: Icon(visuals.icon),
          ),
          title: Text(
            order.orderNumber,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitleParts.join(' · ')),
          trailing: StatusChip(order.status),
        );
      },
    );
  }
}

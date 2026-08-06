import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/message_view.dart';
import 'order_list_tile.dart';
import 'orders_cubit.dart';

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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myOrders)),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) => switch (state) {
          OrdersLoading() => const Center(child: CircularProgressIndicator()),
          OrdersError() => MessageView(
              icon: Icons.error_outline,
              title: l10n.somethingWentWrong,
              message: l10n.errorLoadFailed,
            ),
          OrdersLoaded(:final orders) => orders.isEmpty
              ? _EmptyOrders()
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
    final l10n = context.l10n;
    return MessageView(
      icon: Icons.receipt_long_outlined,
      title: l10n.noOrdersTitle,
      message: l10n.noOrdersMessage,
      action: FilledButton.tonalIcon(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.storefront_outlined),
        label: Text(l10n.browseProducts),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) => OrderListTile(
        order: orders[index],
        onTap: () => context.push('/orders/${orders[index].id}'),
      ),
    );
  }
}

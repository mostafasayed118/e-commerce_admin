import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/message_view.dart';
import '../../orders/order_list_tile.dart';
import '../../orders/status_visuals.dart';
import 'admin_orders_cubit.dart';

/// Admin order management: every order with a status filter chip row, tap to
/// open the detail (where status transitions happen). DI-owned cubit provided
/// by **value**.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminOrdersCubit>.value(
      value: getIt<AdminOrdersCubit>(),
      child: const _AdminOrdersView(),
    );
  }
}

class _AdminOrdersView extends StatelessWidget {
  const _AdminOrdersView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orders)),
      body: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
        builder: (context, state) => switch (state) {
          AdminOrdersLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminOrdersError() => const ErrorView(),
          AdminOrdersLoaded() => _LoadedOrders(state: state),
        },
      ),
    );
  }
}

class _LoadedOrders extends StatelessWidget {
  const _LoadedOrders({required this.state});

  final AdminOrdersLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminOrdersCubit>();
    final l10n = context.l10n;
    return Column(
      children: [
        _FilterChips(
          selected: state.filter,
          onSelected: cubit.setFilter,
        ),
        Expanded(
          child: state.visibleOrders.isEmpty
              ? MessageView(
                  icon: Icons.receipt_long_outlined,
                  title: state.filter == null
                      ? l10n.noOrdersTitle
                      // toLowerCase() is the English "sentence case" shape the
                      // original used; it is a no-op for Arabic (no letter case).
                      : l10n.noFilterOrdersTitle(
                          orderStatusLabel(context, state.filter!).toLowerCase(),
                        ),
                  message: state.filter == null
                      ? l10n.ordersWillAppear
                      : l10n.tryDifferentFilter,
                  action: state.filter == null
                      ? null
                      : TextButton(
                          onPressed: () => cubit.setFilter(null),
                          child: Text(l10n.showAllOrders),
                        ),
                )
              : _OrderList(orders: state.visibleOrders),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          Padding(
            // Directional so the gap flips to the leading edge in RTL (Task 23).
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(context.l10n.all),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              showCheckmark: false,
            ),
          ),
          for (final status in OrderStatus.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(orderStatusLabel(context, status)),
                selected: selected == status,
                onSelected: (_) => onSelected(status),
                showCheckmark: false,
              ),
            ),
        ],
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
        onTap: () => context.push('/admin/orders/${orders[index].id}'),
      ),
    );
  }
}

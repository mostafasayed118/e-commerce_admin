import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/utils/money.dart';
import '../../../widgets/message_view.dart';
import '../../orders/order_list_tile.dart';
import '../../orders/status_visuals.dart';
import 'admin_overview_cubit.dart';

/// The admin dashboard: derived metrics (revenue, orders, low stock), the
/// orders-by-status bar chart, recent orders, and low-stock alerts. Every
/// number comes from [AdminOverviewCubit]'s in-memory derivation of the live
/// watch streams — nothing here queries the database directly.
class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminOverviewCubit>.value(
      value: getIt<AdminOverviewCubit>(),
      child: const _OverviewView(),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: BlocBuilder<AdminOverviewCubit, AdminOverviewState>(
        builder: (context, state) => switch (state) {
          AdminOverviewLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminOverviewError(:final message) => MessageView(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: message,
            ),
          AdminOverviewLoaded() => _Dashboard(state: state),
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.state});

  final AdminOverviewLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Stat cards ----------------------------------------------------
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              icon: Icons.attach_money,
              label: 'Revenue',
              value: formatCents(state.revenueCents),
            ),
            _StatCard(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              value: '${state.totalOrders}',
            ),
            _StatCard(
              icon: Icons.warning_amber_outlined,
              label: 'Low stock',
              value: '${state.lowStockProducts.length}',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Orders by status chart ---------------------------------------
        const _SectionHeader('Orders by status'),
        const SizedBox(height: 12),
        _OrdersByStatusChart(
          byStatus: state.ordersByStatus,
        ),
        const SizedBox(height: 24),

        // --- Recent orders -------------------------------------------------
        const _SectionHeader('Recent orders'),
        const SizedBox(height: 4),
        if (state.recentOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No orders yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final order in state.recentOrders)
            OrderListTile(
              order: order,
              onTap: () => context.push('/admin/orders/${order.id}'),
            ),
        const SizedBox(height: 24),

        // --- Low stock alerts ---------------------------------------------
        const _SectionHeader('Low stock'),
        const SizedBox(height: 4),
        if (state.lowStockProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'All stocked up.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final product in state.lowStockProducts)
            _LowStockTile(product: product),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              // Flexible: labelMedium carries letterSpacing, which Flutter
              // adds after every glyph — a long label can exceed the card's
              // fixed width by a fraction and overflow. Ellipsize instead.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// Bar chart of order counts per status, colored by each status's theme
/// tokens (orderStatusVisuals). Zero-count statuses render as empty slots so
/// the axis is stable.
class _OrdersByStatusChart extends StatelessWidget {
  const _OrdersByStatusChart({required this.byStatus});

  final Map<OrderStatus, int> byStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statuses = OrderStatus.values;
    final maxCount =
        statuses.map((s) => byStatus[s] ?? 0).fold(0, (a, b) => a > b ? a : b);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxCount + 1).toDouble(),
              barGroups: [
                for (var i = 0; i < statuses.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (byStatus[statuses[i]] ?? 0).toDouble(),
                        color: orderStatusVisuals(statuses[i], scheme).color,
                        width: 26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= statuses.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          statuses[index].label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x;
                    if (index < 0 || index >= statuses.length) return null;
                    return BarTooltipItem(
                      '${statuses[index].label}: '
                      '${byStatus[statuses[index]]}',
                      theme.textTheme.labelMedium!.copyWith(
                        color: scheme.onInverseSurface,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final out = product.isOutOfStock;
    final color = out ? scheme.error : scheme.tertiary;
    final background = out ? scheme.errorContainer : scheme.tertiaryContainer;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/admin/products/${product.id}/edit'),
      leading: CircleAvatar(
        backgroundColor: background,
        foregroundColor: color,
        child: Icon(
          out ? Icons.block : Icons.warning_amber_outlined,
          size: 20,
        ),
      ),
      title: Text(product.name, style: theme.textTheme.titleSmall),
      subtitle: Text(
        out ? 'Out of stock' : 'Only ${product.stock} left',
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
      trailing: Text(
        formatCents(product.finalPriceCents),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

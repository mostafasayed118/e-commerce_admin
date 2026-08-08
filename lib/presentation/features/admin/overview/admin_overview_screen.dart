import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/section_header.dart';
import '../../orders/order_list_tile.dart';
import 'admin_overview_cubit.dart';
import 'widgets/coupon_usage_tile.dart';
import 'widgets/low_stock_tile.dart';
import 'widgets/order_volume_chart.dart';
import 'widgets/orders_by_status_chart.dart';
import 'widgets/revenue_trend_chart.dart';
import 'widgets/stat_card.dart';
import 'widgets/top_coupon_tile.dart';
import 'widgets/top_product_tile.dart';

/// The admin dashboard: derived metrics (revenue, orders, low stock), the
/// orders-by-status bar chart, recent orders, and low-stock alerts. Every
/// number comes from [AdminOverviewCubit]'s in-memory derivation of the live
/// watch streams — nothing here queries the database directly. The sections
/// live in `widgets/` (StatCard, OrdersByStatusChart, LowStockTile).
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.overviewTitle)),
      body: BlocBuilder<AdminOverviewCubit, AdminOverviewState>(
        builder: (context, state) => switch (state) {
          AdminOverviewLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminOverviewError() => const ErrorView(),
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
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Stat cards ----------------------------------------------------
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatCard(
              icon: Icons.attach_money,
              label: l10n.revenue,
              value: context.formatCents(state.revenueCents),
            ),
            StatCard(
              icon: Icons.receipt_long_outlined,
              label: l10n.orders,
              value: context.localizeDigits('${state.totalOrders}'),
            ),
            StatCard(
              icon: Icons.warning_amber_outlined,
              label: l10n.lowStock,
              value: context.localizeDigits('${state.lowStockProducts.length}'),
            ),
            StatCard(
              icon: Icons.confirmation_number_outlined,
              label: l10n.overviewActiveCoupons,
              value: context.localizeDigits('${state.activeCouponCount}'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Sales trends ------------------------------------------------
        // Revenue and order volume across the trailing 7-day window,
        // sharing the SectionHeader row's trailing "Last 7 days" caption so
        // the window is self-documenting without a second header.
        Row(
          children: [
            Expanded(child: SectionHeader(l10n.revenueTrendTitle)),
            Text(
              context.localizeDigits(l10n.last7Days),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RevenueTrendChart(trend: state.dailyTrend),
        const SizedBox(height: 24),

        SectionHeader(l10n.orderVolumeTitle),
        const SizedBox(height: 12),
        OrderVolumeChart(trend: state.dailyTrend),
        const SizedBox(height: 24),

        // --- Orders by status chart ---------------------------------------
        SectionHeader(l10n.ordersByStatus),
        const SizedBox(height: 12),
        OrdersByStatusChart(
          byStatus: state.ordersByStatus,
        ),
        const SizedBox(height: 24),

        // --- Recent orders -------------------------------------------------
        SectionHeader(l10n.recentOrders),
        const SizedBox(height: 4),
        if (state.recentOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.noOrdersYet,
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

        // --- Top products --------------------------------------------------
        SectionHeader(l10n.topProductsTitle),
        const SizedBox(height: 4),
        if (state.topProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.noTopProducts,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final ranking in state.topProducts)
            TopProductTile(ranking: ranking),
        const SizedBox(height: 24),

        // --- Top coupons ---------------------------------------------------
        SectionHeader(l10n.topCouponsTitle),
        const SizedBox(height: 4),
        if (state.topCoupons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.noTopCoupons,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final ranking in state.topCoupons)
            TopCouponTile(
              ranking: ranking,
              // The Coupons tab is a shell branch: `go` (not push) switches
              // to it in place, keeping the dashboard alive in the stack.
              onTap: () => context.go('/admin/coupons'),
            ),
        const SizedBox(height: 24),

        // --- Coupon usage --------------------------------------------------
        SectionHeader(l10n.couponUsageTitle),
        const SizedBox(height: 4),
        if (state.recentCouponUses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.noCouponUsage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final usage in state.recentCouponUses)
            CouponUsageTile(
              usage: usage,
              onTap: () => context.push('/admin/orders/${usage.orderId}'),
            ),
        const SizedBox(height: 24),

        // --- Low stock alerts ---------------------------------------------
        SectionHeader(l10n.lowStock),
        const SizedBox(height: 4),
        if (state.lowStockProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.allStockedUp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final product in state.lowStockProducts)
            LowStockTile(product: product),
      ],
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/entities/order_status.dart';
import '../../../orders/status_visuals.dart';

/// Bar chart of order counts per status, colored by each status's theme
/// tokens (orderStatusVisuals). Zero-count statuses render as empty slots so
/// the axis is stable.
class OrdersByStatusChart extends StatelessWidget {
  const OrdersByStatusChart({super.key, required this.byStatus});

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
                          orderStatusLabel(context, statuses[index]),
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
                      '${orderStatusLabel(context, statuses[index])}: '
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

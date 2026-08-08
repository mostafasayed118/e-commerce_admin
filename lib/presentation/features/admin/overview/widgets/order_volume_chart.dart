import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n_ext.dart';
import '../../../orders/order_date_format.dart';
import '../admin_overview_state.dart';

/// Bar chart of the dashboard's daily order count across the trailing
/// trend window (oldest first). Mirrors [OrdersByStatusChart]'s layout so
/// the two dashboard charts stay visually consistent: same card padding,
/// hidden y-axis, day-of-month labels in the active locale's digits, and a
/// tooltip carrying the full date + count.
class OrderVolumeChart extends StatelessWidget {
  const OrderVolumeChart({super.key, required this.trend});

  final List<DailyTrend> trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final maxCount = trend.fold<int>(
      0,
      (m, d) => d.orderCount > m ? d.orderCount : m,
    );

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
                for (var i = 0; i < trend.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: trend[i].orderCount.toDouble(),
                        color: scheme.tertiary,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
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
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= trend.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          context.localizeDigits(
                            '${trend[index].day.day}',
                          ),
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
                    if (index < 0 || index >= trend.length) return null;
                    final day = trend[index].day;
                    final label = context.localizeDigits(
                      '${trend[index].orderCount}',
                    );
                    return BarTooltipItem(
                      // Date + count, both localized (the date formatter and
                      // localizeDigits under `ar`).
                      '${formatOrderDate(day, locale: locale)}\n$label',
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

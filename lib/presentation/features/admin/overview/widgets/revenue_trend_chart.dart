import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/utils/money.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../orders/order_date_format.dart';
import '../admin_overview_state.dart';

/// Line chart of the dashboard's daily revenue across the trailing trend
/// window (oldest first). The y-axis is hidden — the tooltip carries the
/// formatted amount — and the x-axis labels the day of month (converted to
/// the active locale's digits), so the chart stays compact at phone width.
class RevenueTrendChart extends StatelessWidget {
  const RevenueTrendChart({super.key, required this.trend});

  final List<DailyTrend> trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final maxRevenue = trend.fold<int>(
      0,
      (m, d) => d.revenueCents > m ? d.revenueCents : m,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              // The cubit always emits [trendDays] entries, but guard the
              // axis anyway so an empty list can't produce a degenerate
              // maxX < minX chart.
              maxX: (trend.length - 1).clamp(0, 1e9).toDouble(),
              minY: 0,
              // Headroom above the tallest day; a flat all-zero trend still
              // gets a sane axis.
              maxY: maxRevenue == 0 ? 1 : maxRevenue * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < trend.length; i++)
                      FlSpot(i.toDouble(), trend[i].revenueCents.toDouble()),
                  ],
                  isCurved: true,
                  color: scheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
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
                          // The day-of-month label follows the active
                          // locale's digits, like prices and dates.
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) => [
                    for (final touched in touchedSpots)
                      _tooltipItem(
                        context,
                        touched.x.toInt(),
                        scheme,
                        locale,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LineTooltipItem _tooltipItem(
    BuildContext context,
    int index,
    ColorScheme scheme,
    String locale,
  ) {
    final day = trend[index].day;
    return LineTooltipItem(
      // The date renders through the locale formatter; the amount through
      // formatCents — both already Eastern under `ar`.
      '${formatOrderDate(day, locale: locale)}\n'
      '${formatCents(trend[index].revenueCents, locale: locale)}',
      Theme.of(context).textTheme.labelMedium!.copyWith(
        color: scheme.onInverseSurface,
      ),
    );
  }
}

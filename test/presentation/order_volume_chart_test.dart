import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/overview/admin_overview_state.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/order_volume_chart.dart';

/// Pumps the chart under the app's localization delegates (it reads
/// `context.localizeDigits` and formats dates per locale).
Widget wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

/// A 7-day volume trend: 0, 1, 2, 0, 0, 1, 1 orders.
List<DailyTrend> trend() => [
      DailyTrend(day: DateTime(2026, 7, 24), revenueCents: 0, orderCount: 0),
      DailyTrend(day: DateTime(2026, 7, 25), revenueCents: 1000, orderCount: 1),
      DailyTrend(day: DateTime(2026, 7, 26), revenueCents: 2500, orderCount: 2),
      DailyTrend(day: DateTime(2026, 7, 27), revenueCents: 0, orderCount: 0),
      DailyTrend(day: DateTime(2026, 7, 28), revenueCents: 0, orderCount: 0),
      DailyTrend(day: DateTime(2026, 7, 29), revenueCents: 4000, orderCount: 1),
      DailyTrend(day: DateTime(2026, 7, 30), revenueCents: 1000, orderCount: 1),
    ];

void main() {
  testWidgets('renders a bar chart with one group per trend day',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OrderVolumeChart(trend: trend())));

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(7));
    // Bars carry the per-day count; the tallest day (2) defines the axis.
    expect(chart.data.maxY, 3);
  });

  testWidgets('day-of-month labels render in the active locale digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OrderVolumeChart(trend: trend())));

    expect(find.text('24'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('Arabic renders day labels in Eastern digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      OrderVolumeChart(trend: trend()),
      locale: const Locale('ar'),
    ));

    expect(find.text('٢٤'), findsOneWidget);
    expect(find.text('٣٠'), findsOneWidget);
    expect(find.text('24'), findsNothing);
  });
}

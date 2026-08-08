import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/overview/admin_overview_state.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/revenue_trend_chart.dart';

/// Pumps the chart under the app's localization delegates (it reads
/// `context.l10n`, `context.localizeDigits`, and formats dates/money per
/// locale), mirroring the overview-tile tests.
Widget wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

/// A 7-day trend with a distinct spike: $0, $0, $25.00, $0, $0, $40.00, $10.00.
List<DailyTrend> trend() => [
      DailyTrend(day: DateTime(2026, 7, 24), revenueCents: 0, orderCount: 0),
      DailyTrend(day: DateTime(2026, 7, 25), revenueCents: 0, orderCount: 0),
      DailyTrend(day: DateTime(2026, 7, 26), revenueCents: 2500, orderCount: 1),
      DailyTrend(day: DateTime(2026, 7, 27), revenueCents: 0, orderCount: 0),
      DailyTrend(day: DateTime(2026, 7, 28), revenueCents: 0, orderCount: 0),
      DailyTrend(day: DateTime(2026, 7, 29), revenueCents: 4000, orderCount: 2),
      DailyTrend(day: DateTime(2026, 7, 30), revenueCents: 1000, orderCount: 1),
    ];

void main() {
  testWidgets('renders a line chart with one spot per trend day',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(RevenueTrendChart(trend: trend())));

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final data = chart.data;
    expect(data.lineBarsData, hasLength(1));
    expect(data.lineBarsData.first.spots, hasLength(7));
  });

  testWidgets('day-of-month labels render in the active locale digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(RevenueTrendChart(trend: trend())));

    // Day-of-month x labels: 24 .. 30.
    expect(find.text('24'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    // No revenue text leaks onto the axis (the tooltip carries it).
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('Arabic renders day labels in Eastern digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      RevenueTrendChart(trend: trend()),
      locale: const Locale('ar'),
    ));

    expect(find.text('٢٤'), findsOneWidget);
    expect(find.text('٣٠'), findsOneWidget);
    expect(find.text('24'), findsNothing);
  });

  testWidgets('an all-zero trend renders without a degenerate axis',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(RevenueTrendChart(
      trend: [
        for (var i = 0; i < 7; i++)
          DailyTrend(
            day: DateTime(2026, 7, 24 + i),
            revenueCents: 0,
            orderCount: 0,
          ),
      ],
    )));

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.maxY, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

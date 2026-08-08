import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/orders_by_status_chart.dart';

/// Pumps the chart under the app's localization delegates (it reads
/// `context.l10n` / `orderStatusLabel`).
Future<void> pumpChart(
  WidgetTester tester, {
  required Map<OrderStatus, int> byStatus,
  Locale? locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: OrdersByStatusChart(byStatus: byStatus)),
    ),
  );
  await tester.pumpAndSettle(); // fl_chart's implicit animations
}

void main() {
  testWidgets('renders a bar chart with every status label',
      (WidgetTester tester) async {
    await pumpChart(tester, byStatus: {
      OrderStatus.pending: 3,
      OrderStatus.confirmed: 1,
    });

    expect(find.byType(BarChart), findsOneWidget);
    // The axis is stable: all five statuses get a bottom label, zero-count
    // ones included (empty slots).
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Shipped'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('a fully zero map still renders the stable axis',
      (WidgetTester tester) async {
    await pumpChart(tester, byStatus: const {});

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('Arabic renders the localized status labels',
      (WidgetTester tester) async {
    await pumpChart(
      tester,
      byStatus: {OrderStatus.delivered: 2},
      locale: const Locale('ar'),
    );

    expect(find.text('قيد الانتظار'), findsOneWidget);
    expect(find.text('تم التوصيل'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/orders/widgets/order_status_timeline.dart';

/// Isolated tests for [OrderStatusTimeline]: one localized status + formatted
/// timestamp per entry (oldest first), the latest entry emphasized, and an
/// empty history rendering nothing.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('renders one localized status and date per entry, oldest first',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OrderStatusTimeline(history: [
      OrderStatusEntry(
        status: OrderStatus.pending,
        changedAt: DateTime(2026, 8, 5, 9, 5),
      ),
      OrderStatusEntry(
        status: OrderStatus.confirmed,
        changedAt: DateTime(2026, 8, 6, 10, 30),
      ),
    ])));

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('5 Aug 2026, 09:05'), findsOneWidget);
    expect(find.text('6 Aug 2026, 10:30'), findsOneWidget);
  });

  testWidgets('emphasizes the latest entry with the heavier weight',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OrderStatusTimeline(history: [
      OrderStatusEntry(
        status: OrderStatus.pending,
        changedAt: DateTime(2026, 8, 5),
      ),
      OrderStatusEntry(
        status: OrderStatus.delivered,
        changedAt: DateTime(2026, 8, 6),
      ),
    ])));

    final pending = tester.widget<Text>(find.text('Pending'));
    final delivered = tester.widget<Text>(find.text('Delivered'));
    expect(pending.style?.fontWeight, FontWeight.w500);
    expect(delivered.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('renders nothing for an empty history',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const OrderStatusTimeline(history: [])));

    expect(find.byType(OrderStatusTimeline), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}

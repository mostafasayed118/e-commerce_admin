import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/features/admin/overview/widgets/stat_card.dart';

/// Isolated tests for the dashboard [StatCard]: icon, label and big value.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the icon, label and value', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const StatCard(
      icon: Icons.attach_money,
      label: 'Revenue',
      value: r'$1,234.56',
    )));

    expect(find.byIcon(Icons.attach_money), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text(r'$1,234.56'), findsOneWidget);
  });

  testWidgets('renders the value in the emphasized headline style',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const StatCard(
      icon: Icons.receipt_long_outlined,
      label: 'Orders',
      value: '42',
    )));

    final value = tester.widget<Text>(find.text('42'));
    expect(value.style?.fontWeight, FontWeight.w700);
    // A long label ellipsizes rather than overflowing the fixed card width.
    final label = tester.widget<Text>(find.text('Orders'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
  });
}

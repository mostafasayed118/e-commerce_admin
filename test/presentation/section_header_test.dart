import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/widgets/section_header.dart';

/// Isolated tests for the shared [SectionHeader]: the all-caps rendering and
/// the Latin-only tracking (spaced-out Arabic glyphs look broken, so RTL
/// gets no letter-spacing).
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the label uppercased', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SectionHeader('Recent Orders')));

    expect(find.text('RECENT ORDERS'), findsOneWidget);
    expect(find.text('Recent Orders'), findsNothing);
  });

  testWidgets('tracks the letters in LTR and not in RTL',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SectionHeader('Orders')));
    Text ltrText = tester.widget(find.text('ORDERS'));
    expect(ltrText.style?.letterSpacing, 1.2);

    await tester.pumpWidget(wrap(Directionality(
      textDirection: TextDirection.rtl,
      child: const SectionHeader('Orders'),
    )));
    Text rtlText = tester.widget(find.text('ORDERS'));
    expect(rtlText.style?.letterSpacing, 0);
  });
}

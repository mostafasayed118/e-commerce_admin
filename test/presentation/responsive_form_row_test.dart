import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/widgets/responsive/responsive_form_row.dart';

/// Isolated tests for the shared [ResponsiveFormRow] widget: fields stack on
/// narrow surfaces and sit side-by-side (each Expanded) on wide ones.
void main() {
  Widget wrap(Widget child, double width) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: 600, child: child),
        ),
      );

  const fields = ResponsiveFormRow(
    children: [
      TextField(key: Key('a')),
      TextField(key: Key('b')),
      TextField(key: Key('c')),
    ],
  );

  testWidgets('below the breakpoint the fields stack in a Column',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(fields, 390));

    final a = tester.getTopLeft(find.byKey(const Key('a')));
    final b = tester.getTopLeft(find.byKey(const Key('b')));
    final c = tester.getTopLeft(find.byKey(const Key('c')));
    expect(a.dx, b.dx);
    expect(b.dy, greaterThan(a.dy));
    expect(c.dy, greaterThan(b.dy));
  });

  testWidgets('at and above the breakpoint the fields share one row',
      (WidgetTester tester) async {
    // Default breakpoint is 700; a wide admin test surface (800) is a row.
    await tester.pumpWidget(wrap(fields, 800));

    final a = tester.getTopLeft(find.byKey(const Key('a')));
    final b = tester.getTopLeft(find.byKey(const Key('b')));
    final c = tester.getTopLeft(find.byKey(const Key('c')));
    expect(a.dy, b.dy);
    expect(b.dx, greaterThan(a.dx));
    expect(c.dx, greaterThan(b.dx));
  });

  testWidgets('row mode expands each child equally', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(fields, 800));

    final aWidth = tester.getSize(find.byKey(const Key('a'))).width;
    final bWidth = tester.getSize(find.byKey(const Key('b'))).width;
    final cWidth = tester.getSize(find.byKey(const Key('c'))).width;
    expect(aWidth, bWidth);
    expect(bWidth, cWidth);
    // 800 - 2 * 16 spacing, divided across 3 fields.
    expect(aWidth, closeTo((800 - 32) / 3, 0.1));
  });

  testWidgets('a custom breakpoint changes where the split happens',
      (WidgetTester tester) async {
    const row = ResponsiveFormRow(
      breakpoint: 500,
      children: [TextField(key: Key('x')), TextField(key: Key('y'))],
    );
    await tester.pumpWidget(wrap(row, 400));
    expect(
      tester.getTopLeft(find.byKey(const Key('x'))).dx,
      tester.getTopLeft(find.byKey(const Key('y'))).dx,
    );

    await tester.pumpWidget(wrap(row, 500));
    expect(
      tester.getTopLeft(find.byKey(const Key('y'))).dx,
      greaterThan(tester.getTopLeft(find.byKey(const Key('x'))).dx),
    );
  });
}

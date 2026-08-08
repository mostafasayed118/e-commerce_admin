import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/orders/widgets/order_total_row.dart';

/// Pumps the row under the app's localization delegates (it reads
/// `context.formatCents`), mirroring the other widget tests.
Future<void> pumpRow(
  WidgetTester tester, {
  required String label,
  required int cents,
  bool negative = false,
  bool highlight = false,
  bool bold = false,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OrderTotalRow(
            label: label,
            cents: cents,
            negative: negative,
            highlight: highlight,
            bold: bold,
          ),
        ),
      ),
    );

void main() {
  testWidgets('renders the label and formatted amount',
      (WidgetTester tester) async {
    await pumpRow(tester, label: 'Subtotal', cents: 1234);

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(r'$12.34'), findsOneWidget);
  });

  testWidgets('negative flips the sign through the locale formatter',
      (WidgetTester tester) async {
    // The sign is applied to the *cents* so the locale places it correctly
    // (the hand-written '-' would land on the wrong side in RTL).
    await pumpRow(tester, label: 'Savings', cents: 1234, negative: true);

    expect(find.text(r'-$12.34'), findsOneWidget);
  });

  testWidgets('highlight tints the value with the primary color',
      (WidgetTester tester) async {
    await pumpRow(
      tester,
      label: 'Savings',
      cents: 500,
      negative: true,
      highlight: true,
    );

    final theme = Theme.of(tester.element(find.text(r'-$5.00')));
    final value = tester.widget<Text>(find.text(r'-$5.00'));
    expect(value.style?.color, theme.colorScheme.primary);
  });

  testWidgets('bold emphasizes label and value weights',
      (WidgetTester tester) async {
    await pumpRow(tester, label: 'Total', cents: 3000, bold: true);

    final label = tester.widget<Text>(find.text('Total'));
    final value = tester.widget<Text>(find.text(r'$30.00'));
    expect(label.style?.fontWeight, FontWeight.w600);
    expect(value.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('Arabic renders the amount in Eastern digits',
      (WidgetTester tester) async {
    await pumpRow(
      tester,
      label: 'الإجمالي',
      cents: 1234,
      locale: const Locale('ar'),
    );

    // formatCents under ar keeps the $ symbol and decimal point, converts
    // only the digits ($12.34 → ١٢.٣٤ $).
    expect(find.textContaining('١٢.٣٤'), findsOneWidget);
    expect(find.textContaining('12.34'), findsNothing);
  });
}

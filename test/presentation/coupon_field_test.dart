import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/checkout/widgets/coupon_field.dart';

/// Pumps the field under the app's localization delegates (it reads
/// `context.l10n` / `context.formatCents`).
Future<void> pumpField(
  WidgetTester tester, {
  TextEditingController? controller,
  String? appliedCode,
  int appliedDiscountCents = 0,
  String? errorText,
  VoidCallback? onApply,
  VoidCallback? onRemove,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CouponField(
            controller: controller ?? TextEditingController(),
            appliedCode: appliedCode,
            appliedDiscountCents: appliedDiscountCents,
            errorText: errorText,
            onApply: onApply ?? () {},
            onRemove: onRemove ?? () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('no applied code shows the entry field and Apply button',
      (WidgetTester tester) async {
    await pumpField(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('tapping Apply fires the callback with the entered code',
      (WidgetTester tester) async {
    final controller = TextEditingController(text: 'SAVE10');
    String? applied;
    await pumpField(
      tester,
      controller: controller,
      onApply: () => applied = controller.text,
    );

    await tester.tap(find.text('Apply'));
    expect(applied, 'SAVE10');
  });

  testWidgets('an applied code swaps to the chip with remove',
      (WidgetTester tester) async {
    var removed = 0;
    await pumpField(
      tester,
      appliedCode: 'SAVE10',
      appliedDiscountCents: 500,
      onRemove: () => removed++,
    );

    expect(find.byType(TextField), findsNothing);
    // "SAVE10 · −$5.00" (the minus is the U+2212 the field renders).
    expect(find.text('SAVE10 · −\$5.00'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    expect(removed, 1);
  });

  testWidgets('renders the inline error text when provided',
      (WidgetTester tester) async {
    await pumpField(tester, errorText: 'NOPE is not a valid code.');

    expect(find.text('NOPE is not a valid code.'), findsOneWidget);
  });

  testWidgets('Arabic renders the applied discount in Eastern digits',
      (WidgetTester tester) async {
    await pumpField(
      tester,
      appliedCode: 'SAVE10',
      appliedDiscountCents: 500,
      locale: const Locale('ar'),
    );

    // ar formatCents wraps the amount in bidi marks, so assert on the digit
    // run (same convention as product_price_row_test's ar assertions).
    expect(find.textContaining('٥.٠٠'), findsOneWidget);
    expect(find.textContaining('5.00'), findsNothing);
  });
}

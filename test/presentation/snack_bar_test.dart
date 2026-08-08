import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/widgets/snack_bar.dart';

/// Pumps a host Scaffold whose button triggers the helper under test, then
/// taps it — the same shape the real screens use (a callback calling the
/// helper with the current context).
Future<void> pumpAndTrigger(
  WidgetTester tester,
  void Function(BuildContext context) trigger, {
  Locale? locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => trigger(context),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump(); // show the SnackBar
}

void main() {
  testWidgets('showErrorSnackBar renders the localized error message',
      (WidgetTester tester) async {
    await pumpAndTrigger(
      tester,
      (context) => showErrorSnackBar(
        context,
        const CouponNotFoundError(couponCode: 'NOPE', message: 'dev log'),
      ),
    );

    // The error maps through context.errorText — the code→message mapping,
    // not the raw dev-log message.
    expect(find.text('NOPE is not a valid code.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5)); // flush the auto-dismiss
    await tester.pumpAndSettle();
  });

  testWidgets('showErrorSnackBar localizes data digits in Arabic',
      (WidgetTester tester) async {
    await pumpAndTrigger(
      tester,
      (context) => showErrorSnackBar(
        context,
        const CouponUsageLimitError(
          couponCode: 'SAVE10',
          maxUses: 5,
          message: 'dev log',
        ),
      ),
      locale: const Locale('ar'),
    );

    // Same contract as error_message_test: the cap converts to Eastern
    // digits, the code's own digit converts too (documented tradeoff).
    expect(
      find.text('بلغ الرمز SAVE١٠ الحد الأقصى لاستخداماته (٥).'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('showSuccessSnackBar shows the plain success message',
      (WidgetTester tester) async {
    await pumpAndTrigger(
      tester,
      (context) => showSuccessSnackBar(context, 'Profile saved.'),
    );

    expect(find.text('Profile saved.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

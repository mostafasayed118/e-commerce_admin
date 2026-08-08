import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/l10n/error_messages.dart';

/// Renders whatever string [builder] produces, so tests can exercise the
/// code → localized-message mapping inside a real Localizations context.
class _MappingProbe extends StatelessWidget {
  const _MappingProbe({required this.builder});

  final String Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) => Text(builder(context));
}

/// Pumps the probe under the app's localization delegates (Task 23 refactor:
/// the mapping functions need AppLocalizations, exactly like the screens do).
Widget probe(String Function(BuildContext) builder, {Locale? locale}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _MappingProbe(builder: builder),
    );

void main() {
  testWidgets('a plain code maps to its English message by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => errorTextForCode(context, AppErrorCode.cartEmpty),
    ));

    expect(find.text('Your cart is empty.'), findsOneWidget);
  });

  testWidgets('StockLimitError renders its data and the in-cart hint',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const StockLimitError(
          productName: 'Classic Tee',
          stock: 3,
          currentInCart: 2,
          message: 'dev log',
        ),
      ),
    ));

    expect(
      find.text(
        'Only 3 left in stock for Classic Tee. You already have 2 in your cart.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('StockLimitError without an in-cart amount omits the hint',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const StockLimitError(
          productName: 'Classic Tee',
          stock: 3,
          currentInCart: 0,
          message: 'dev log',
        ),
      ),
    ));

    expect(find.text('Only 3 left in stock for Classic Tee.'), findsOneWidget);
  });

  testWidgets('ProductOutOfStockError interpolates the product name',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const ProductOutOfStockError(
          productName: 'Leather Belt',
          message: 'dev log',
        ),
      ),
    ));

    expect(find.text('Leather Belt is out of stock.'), findsOneWidget);
  });

  testWidgets('CategoryInUseError uses the singular form for one product',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CategoryInUseError(productCount: 1, message: 'dev log'),
      ),
    ));

    expect(
      find.text(
        'This category has 1 product. Delete it before deleting the category.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('CategoryInUseError pluralizes the product count',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CategoryInUseError(productCount: 3, message: 'dev log'),
      ),
    ));

    expect(
      find.text(
        'This category has 3 products. Delete them before deleting the category.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('CouponNotFoundError interpolates the entered code',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CouponNotFoundError(couponCode: 'NOPE', message: 'dev log'),
      ),
    ));

    expect(find.text('NOPE is not a valid code.'), findsOneWidget);
  });

  testWidgets('CouponExpiredError and CouponInactiveError name the code',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CouponExpiredError(couponCode: 'SAVE10', message: 'dev log'),
      ),
    ));
    expect(find.text('Code SAVE10 has expired.'), findsOneWidget);

    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CouponInactiveError(couponCode: 'SAVE10', message: 'dev log'),
      ),
    ));
    expect(find.text('Code SAVE10 is not active.'), findsOneWidget);
  });

  testWidgets('CouponMinSpendError formats both amounts',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CouponMinSpendError(
          couponCode: 'SAVE10',
          requiredCents: 5000,
          currentCents: 3000,
          message: 'dev log',
        ),
      ),
    ));

    expect(
      find.text(
        'Spend at least \$50.00 to use this code (your subtotal is \$30.00).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('CouponUsageLimitError names the code and the cap',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CouponUsageLimitError(
          couponCode: 'SAVE10',
          maxUses: 5,
          message: 'dev log',
        ),
      ),
    ));

    expect(
      find.text('Code SAVE10 has reached its 5-use limit.'),
      findsOneWidget,
    );
  });

  testWidgets('CouponUsageLimitError localizes the cap digits in Arabic',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CouponUsageLimitError(
          couponCode: 'SAVE10',
          maxUses: 5,
          message: 'dev log',
        ),
      ),
      locale: const Locale('ar'),
    ));

    // The cap renders in Eastern Arabic digits; the code is an identifier
    // whose own digits convert too (SAVE10 → SAVE١٠) — documented tradeoff.
    expect(
      find.text('بلغ الرمز SAVE١٠ الحد الأقصى لاستخداماته (٥).'),
      findsOneWidget,
    );
  });

  testWidgets('StockLimitError localizes its digits in Arabic',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const StockLimitError(
          productName: 'Classic Tee',
          stock: 3,
          currentInCart: 2,
          message: 'dev log',
        ),
      ),
      locale: const Locale('ar'),
    ));

    expect(
      find.text('متبقي ٣ فقط في المخزون من Classic Tee. لديك بالفعل ٢ في سلتك.'),
      findsOneWidget,
    );
  });

  testWidgets('CategoryInUseError localizes its count in Arabic',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CategoryInUseError(productCount: 3, message: 'dev log'),
      ),
      locale: const Locale('ar'),
    ));

    expect(
      find.text('يحتوي هذا التصنيف على ٣ منتجات. احذفها قبل حذف التصنيف.'),
      findsOneWidget,
    );
  });

  testWidgets('the same code localizes to Arabic under the ar locale',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => errorTextForCode(context, AppErrorCode.pinIncorrect),
      locale: const Locale('ar'),
    ));

    expect(find.text('رمز PIN غير صحيح'), findsOneWidget);
  });

  testWidgets('pinFormatError converts the 4-6 range to Eastern digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => errorTextForCode(context, AppErrorCode.pinFormat),
    ));
    expect(find.text('PIN must be 4-6 digits'), findsOneWidget);

    await tester.pumpWidget(probe(
      (context) => errorTextForCode(context, AppErrorCode.pinFormat),
      locale: const Locale('ar'),
    ));
    expect(find.text('يجب أن يتكون رمز PIN من ٤-٦ أرقام'), findsOneWidget);
    expect(find.textContaining('4-6'), findsNothing);
  });

  testWidgets('errorQuantityMin converts its 1 to Eastern digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => errorTextForCode(context, AppErrorCode.quantityMin),
      locale: const Locale('ar'),
    ));
    expect(find.text('يجب أن تكون الكمية ١ على الأقل.'), findsOneWidget);
    expect(find.textContaining('1'), findsNothing);
  });

  testWidgets('every AppErrorCode maps to a non-empty localized string',
      (WidgetTester tester) async {
    // The switch is exhaustive (a new enum value stops compilation), so the
    // remaining contract is that every mapped string is actually present and
    // non-empty in the ARB — guards against a missing or blank value.
    // Data-carrying codes are excluded: their bare form is a developer bug
    // (asserts in debug) and is covered by the fallback test below.
    final dataCarrying = {
      AppErrorCode.productOutOfStock,
      AppErrorCode.stockLimit,
      AppErrorCode.categoryInUse,
      AppErrorCode.couponNotFound,
      AppErrorCode.couponInactive,
      AppErrorCode.couponExpired,
      AppErrorCode.couponMinSpend,
      AppErrorCode.couponUsageLimit,
    };
    final plainCodes =
        AppErrorCode.values.where((code) => !dataCarrying.contains(code));
    final rendered = <String, String>{};
    for (final code in plainCodes) {
      await tester.pumpWidget(probe(
        (context) => errorTextForCode(context, code),
      ));
      final text = tester.widget<Text>(find.byType(Text)).data;
      expect(
        text,
        isNotNull,
        reason: 'AppErrorCode.$code mapped to a null string',
      );
      expect(
        text!.trim(),
        isNotEmpty,
        reason: 'AppErrorCode.$code mapped to an empty string',
      );
      rendered[code.name] = text;
    }
    // Sanity: the loop really visited every plain code and produced distinct
    // messages (a duplicate ARB key would hide silently otherwise).
    expect(rendered.values.toSet().length, plainCodes.length);
  });

  testWidgets('a bare data-carrying code trips the debug guard',
      (WidgetTester tester) async {
    // Bare data-carrying codes are a developer bug: the typed variants in
    // localizedErrorMessage are the only correct path, and the fallback's
    // debug assert is the tripwire that makes the mistake loud instead of a
    // silent degrade to the generic message. Under asserts (every test run)
    // the fallback must THROW, not silently return.
    //
    // Release behavior is the mirror image: with asserts compiled out, the
    // fallback returns [AppErrorCode.database]'s generic message (covered by
    // the every-code test, which pins that string non-empty).
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            try {
              errorTextForCode(context, AppErrorCode.productOutOfStock);
              // Reaching here means the guard silently passed — exactly the
              // silent-degrade bug the assert exists to prevent.
              fail('bare data-carrying code must trip the debug assert');
            } on AssertionError {
              // The intended developer-bug tripwire fired.
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}

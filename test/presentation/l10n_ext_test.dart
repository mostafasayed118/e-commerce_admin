import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/l10n/l10n_ext.dart';

/// The extension helpers hang off [BuildContext], so each locale's assertions
/// run against a context captured inside a [MaterialApp] with that locale.
/// Pumps once per locale; the caller must finish all assertions on a context
/// before pumping the next (the previous element goes defunct).
Future<BuildContext> pumpContext(WidgetTester tester, {Locale? locale}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

const product = Product(
  id: 1,
  categoryId: 1,
  name: 'Classic Tee',
  nameAr: 'تيشيرت كلاسيك',
  description: 'soft cotton',
  descriptionAr: 'قطن ناعم',
  priceCents: 2000,
);

const noArabic = Product(
  id: 2,
  categoryId: 1,
  name: 'Denim Jacket',
  description: 'timeless denim',
  priceCents: 4500,
);

const blankArabic = Product(
  id: 3,
  categoryId: 1,
  name: 'Wool Beanie',
  nameAr: '   ', // blank Arabic content degrades to English
  priceCents: 1200,
);

const item = OrderItem(
  orderId: 1,
  productName: 'Classic Tee',
  productNameAr: 'تيشيرت كلاسيك',
  unitPriceCents: 2000,
  quantity: 1,
);

void main() {
  testWidgets('formatCents uses the active locale (digits + symbol)',
      (WidgetTester tester) async {
    final en = await pumpContext(tester);
    expect(en.formatCents(1234), r'$12.34');
    expect(en.formatCents(123456), r'$1,234.56');
    expect(en.formatCents(-1234), r'-$12.34');

    final ar = await pumpContext(tester, locale: const Locale('ar'));
    final arText = ar.formatCents(1234);
    // Eastern digits, no Western digits; the $ symbol survives. (intl wraps
    // the ar string in bidi marks, so assert on content, not exact shape.)
    expect(arText, isNot(contains('1')));
    expect(arText, contains('١٢'));
    expect(arText, contains(r'$'));
  });

  testWidgets('localizeDigits converts only for ar and is idempotent',
      (WidgetTester tester) async {
    final en = await pumpContext(tester);
    expect(en.localizeDigits('3 uses'), '3 uses');
    expect(en.localizeDigits('60% used'), '60% used');

    final ar = await pumpContext(tester, locale: const Locale('ar'));
    expect(ar.localizeDigits('3 uses'), '٣ uses');
    expect(ar.localizeDigits('60% used'), '٦٠% used');
    // Already-converted digits pass through untouched.
    expect(ar.localizeDigits('٣ uses'), '٣ uses');
  });

  testWidgets('productName picks by locale with an English fallback',
      (WidgetTester tester) async {
    final en = await pumpContext(tester);
    expect(en.productName(product), 'Classic Tee');

    final ar = await pumpContext(tester, locale: const Locale('ar'));
    expect(ar.productName(product), 'تيشيرت كلاسيك');
    // Missing and blank Arabic both fall back to the canonical name.
    expect(ar.productName(noArabic), 'Denim Jacket');
    expect(ar.productName(blankArabic), 'Wool Beanie');
  });

  testWidgets('productDescription picks by locale with an English fallback',
      (WidgetTester tester) async {
    final en = await pumpContext(tester);
    expect(en.productDescription(product), 'soft cotton');

    final ar = await pumpContext(tester, locale: const Locale('ar'));
    expect(ar.productDescription(product), 'قطن ناعم');
    // Missing Arabic falls back to the canonical English description.
    expect(ar.productDescription(noArabic), 'timeless denim');
  });

  testWidgets('categoryName picks by locale with an English fallback',
      (WidgetTester tester) async {
    const category = Category(id: 1, name: 'Clothing', nameAr: 'ملابس');
    const noAr = Category(id: 2, name: 'Electronics');

    final en = await pumpContext(tester);
    expect(en.categoryName(category), 'Clothing');

    final ar = await pumpContext(tester, locale: const Locale('ar'));
    expect(ar.categoryName(category), 'ملابس');
    expect(ar.categoryName(noAr), 'Electronics');
  });

  testWidgets('orderItemName picks by locale with an English fallback',
      (WidgetTester tester) async {
    final en = await pumpContext(tester);
    expect(en.orderItemName(item), 'Classic Tee');

    final ar = await pumpContext(tester, locale: const Locale('ar'));
    expect(ar.orderItemName(item), 'تيشيرت كلاسيك');
  });

  testWidgets('errorText maps the stable code in the active locale',
      (WidgetTester tester) async {
    final en = await pumpContext(tester);
    expect(
      en.errorText(
        const ValidationError(code: AppErrorCode.cartEmpty, message: 'x'),
      ),
      'Your cart is empty.',
    );
    // quantityMin's guidance digit converts through localizeDigits too.
    expect(
      en.errorText(
        const ValidationError(code: AppErrorCode.quantityMin, message: 'x'),
      ),
      'Quantity must be at least 1.',
    );

    final ar = await pumpContext(tester, locale: const Locale('ar'));
    expect(
      ar.errorText(
        const ValidationError(code: AppErrorCode.cartEmpty, message: 'x'),
      ),
      'سلتك فارغة.',
    );
    expect(
      ar.errorText(
        const ValidationError(code: AppErrorCode.quantityMin, message: 'x'),
      ),
      'يجب أن تكون الكمية ١ على الأقل.',
    );
  });

  testWidgets('errorText uses the typed variant data when present',
      (WidgetTester tester) async {
    final en = await pumpContext(tester);
    expect(
      en.errorText(
        const ProductOutOfStockError(
          productName: 'Classic Tee',
          message: 'x',
        ),
      ),
      'Classic Tee is out of stock.',
    );
  });

  test('emptyToNull normalizes blank content to null', () {
    expect(emptyToNull(''), isNull);
    expect(emptyToNull('   '), isNull);
    expect(emptyToNull('x'), 'x');
    expect(emptyToNull(' x '), 'x');
  });
}

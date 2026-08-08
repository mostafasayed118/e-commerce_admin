import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/coupons/admin_coupons_state.dart';
import 'package:shop_admin/presentation/features/admin/coupons/widgets/coupon_list.dart';

Future<void> pumpList(
  WidgetTester tester, {
  required List<Coupon> coupons,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CouponList(
            state: AdminCouponsLoaded(coupons: coupons),
            onEdit: (_) {},
            onDelete: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );

Coupon percentCoupon({int? maxUses, int usedCount = 0}) => Coupon(
      id: 1,
      code: 'SAVE10',
      type: CouponDiscountType.percent,
      value: 10,
      maxUses: maxUses,
      usedCount: usedCount,
    );

void main() {
  testWidgets('Arabic: usage and discount digits become Eastern Arabic',
      (WidgetTester tester) async {
    await pumpList(
      tester,
      coupons: [percentCoupon(maxUses: 5, usedCount: 3)],
      locale: const Locale('ar'),
    );

    // "خصم 10% · 3/5 استخدامات" — every digit in the subtitle converts, so
    // the usage label matches the prices next to it.
    expect(find.text('خصم ١٠% · ٣/٥ استخدامات'), findsOneWidget);
  });

  testWidgets('English: digits stay Western', (WidgetTester tester) async {
    await pumpList(
      tester,
      coupons: [percentCoupon(maxUses: 5, usedCount: 3)],
    );

    expect(find.text('10% off · 3/5 uses'), findsOneWidget);
  });
}

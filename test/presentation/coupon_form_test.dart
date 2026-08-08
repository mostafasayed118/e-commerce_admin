import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/features/admin/coupons/widgets/coupon_form.dart';

import '../helpers/test_app.dart';
import '../helpers/test_di.dart';

/// A router hosting the form on /form (pop target '/'), mirroring the
/// product form test harness.
GoRouter formRouter(CouponForm form) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('home'))),
        ),
        GoRoute(
          path: '/form',
          builder: (context, state) => form,
        ),
      ],
    );

Future<void> pumpForm(WidgetTester tester, CouponForm form, {Locale? locale}) async {
  final router = formRouter(form);
  await pumpRouterSurface(
    tester,
    router: router,
    size: const Size(800, 1600),
    locale: locale,
  );
  router.push('/form');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  testWidgets('edit mode prefills the expiry from the coupon',
      (WidgetTester tester) async {
    final coupon = Coupon(
      id: 3,
      code: 'SUMMER20',
      type: CouponDiscountType.percent,
      value: 20,
      expiresAt: DateTime(2026, 8, 5),
    );
    await pumpForm(tester, CouponForm(coupon: coupon));

    // The expiry row shows the coupon's stored date (shared date formatter,
    // skeleton `d MMM yyyy`).
    expect(find.text('5 Aug 2026'), findsOneWidget);
  });

  testWidgets('Arabic: the expiry date renders Eastern digits',
      (WidgetTester tester) async {
    final coupon = Coupon(
      id: 3,
      code: 'SUMMER20',
      type: CouponDiscountType.percent,
      value: 20,
      expiresAt: DateTime(2026, 8, 5),
    );
    await pumpForm(
      tester,
      CouponForm(coupon: coupon),
      locale: const Locale('ar'),
    );

    // formatOrderDate: Arabic month name AND Eastern digits — the raw intl
    // DateFormat would keep Western digits ('5 أغسطس 2026').
    expect(find.text('٥ أغسطس ٢٠٢٦'), findsOneWidget);
    expect(find.textContaining('2026'), findsNothing);
  });

  testWidgets('Arabic: the min-spend hint renders Eastern digits',
      (WidgetTester tester) async {
    await pumpForm(tester, CouponForm(coupon: null), locale: const Locale('ar'));

    // '0 = no minimum' → '٠ = بدون حد أدنى' (hint text of the empty field).
    expect(find.text('٠ = بدون حد أدنى'), findsOneWidget);
    expect(find.textContaining('0 ='), findsNothing);
  });

  testWidgets('Arabic: the percent validator error renders Eastern digits',
      (WidgetTester tester) async {
    await pumpForm(tester, CouponForm(coupon: null), locale: const Locale('ar'));

    // An out-of-range percent trips the validator: '0-100' → '٠-١٠٠'.
    await tester.enterText(find.byKey(const Key('coupon-value')), '150');
    await tester.tap(find.text('حفظ')); // Save
    await tester.pump();
    expect(find.text('٠-١٠٠'), findsOneWidget);
    expect(find.text('0-100'), findsNothing);
  });
}

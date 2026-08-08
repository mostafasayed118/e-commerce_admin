import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/overview/admin_overview_state.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/coupon_usage_tile.dart';

/// Pumps the tile under the app's localization delegates (it reads
/// `context.l10n` / `context.formatCents` and formats dates per locale),
/// mirroring the other overview-tile tests.
Widget wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

CouponUsageLine usage({DateTime? createdAt}) => CouponUsageLine(
      code: 'SAVE5',
      orderId: 3,
      orderNumber: 'ORD-000003',
      discountCents: 500,
      createdAt: createdAt,
    );

void main() {
  testWidgets('shows the code, order number, date, and discount',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      CouponUsageTile(
        usage: usage(createdAt: DateTime(2026, 8, 5)),
      ),
    ));

    expect(find.text('SAVE5'), findsOneWidget);
    // Subtitle: "ORD-000003 · 5 Aug 2026" (the date runs through the locale
    // formatter).
    expect(find.text('ORD-000003 · 5 Aug 2026'), findsOneWidget);
    // Trailing: the coupon's contribution, shown as a negative amount.
    expect(find.text(r'-$5.00'), findsOneWidget);
    expect(find.byIcon(Icons.confirmation_number), findsOneWidget);
  });

  testWidgets('omits the date segment when the usage has no timestamp',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(CouponUsageTile(usage: usage())));

    expect(find.text('ORD-000003'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('Arabic renders the date in Eastern digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      CouponUsageTile(
        usage: usage(createdAt: DateTime(2026, 8, 5)),
      ),
      locale: const Locale('ar'),
    ));

    // "ORD-000003 · ٥ أغسطس ٢٠٢٦" — the order number is an identifier kept
    // canonical, the date converts to Eastern digits.
    expect(find.text('ORD-000003 · ٥ أغسطس ٢٠٢٦'), findsOneWidget);
  });

  testWidgets('wires the tap callback', (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(
      CouponUsageTile(usage: usage(), onTap: () => tapped++),
    ));

    await tester.tap(find.text('SAVE5'));
    expect(tapped, 1);
  });
}

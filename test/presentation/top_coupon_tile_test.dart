import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/overview/admin_overview_state.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/top_coupon_tile.dart';

Future<void> pumpTile(
  WidgetTester tester,
  TopCouponRanking ranking, {
  VoidCallback? onTap,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TopCouponTile(ranking: ranking, onTap: onTap),
        ),
      ),
    );

void main() {
  testWidgets('shows the code, the redemption count and the bar fill',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(code: 'SAVE5', usedCount: 3, fraction: 1.0),
    );

    expect(find.text('SAVE5'), findsOneWidget);
    expect(find.text('3 uses'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1.0);
  });

  testWidgets('pluralizes the count and fills the bar partially',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(code: 'WELCOME10', usedCount: 1, fraction: 0.5),
    );

    expect(find.text('WELCOME10'), findsOneWidget);
    expect(find.text('1 use'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.5);
  });

  testWidgets('shows the exhaustion percentage for a capped coupon',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(
        code: 'SAVE5',
        usedCount: 3,
        maxUses: 5,
        fraction: 0.6,
      ),
    );

    // A capped coupon's trailing label reads the exhaustion percentage
    // (3 of 5 = 60%), matching the bar — the "close to exhausted" answer.
    expect(find.text('60% used'), findsOneWidget);
    expect(find.text('3 uses'), findsNothing);
    expect(find.text('3/5 uses'), findsNothing);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.6);
  });

  testWidgets('clamps the exhaustion percentage at 100% when a cap was lowered',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(
        code: 'SAVE5',
        usedCount: 4,
        maxUses: 3, // admin lowered the cap below past redemptions
        fraction: 1.0,
      ),
    );

    // The bar clamps to 1.0 and the copy follows — never "133% used".
    expect(find.text('100% used'), findsOneWidget);
    expect(find.text('133% used'), findsNothing);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1.0);
  });

  testWidgets('renders Eastern Arabic digits for a capped coupon in Arabic',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(
        code: 'SAVE5',
        usedCount: 3,
        maxUses: 5,
        fraction: 0.6,
      ),
      locale: const Locale('ar'),
    );

    expect(find.text('٦٠% مستخدمة'), findsOneWidget);
    expect(find.text('60% used'), findsNothing);
  });

  testWidgets('renders Eastern Arabic digits for the count in Arabic',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(code: 'WELCOME10', usedCount: 3, fraction: 0.5),
      locale: const Locale('ar'),
    );

    expect(find.text('٣ استخدامات'), findsOneWidget);
    expect(find.text('3 uses'), findsNothing);
  });

  testWidgets('treats a degenerate zero cap as unlimited (plain count)',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(
        code: 'SAVE5',
        usedCount: 5,
        maxUses: 0, // the ranking can't produce this — defensive guard
        fraction: 1.0,
      ),
    );

    // A zero cap falls back to the plain count instead of dividing by zero.
    expect(find.text('5 uses'), findsOneWidget);
    expect(find.text('0% used'), findsNothing);
  });

  testWidgets('invokes onTap when tapped', (WidgetTester tester) async {
    var tapped = false;
    await pumpTile(
      tester,
      const TopCouponRanking(code: 'SAVE5', usedCount: 3, fraction: 1.0),
      onTap: () => tapped = true,
    );

    await tester.tap(find.text('SAVE5'));

    expect(tapped, isTrue);
  });

  testWidgets('a tile without onTap is still tappable-looking but inert',
      (WidgetTester tester) async {
    await pumpTile(
      tester,
      const TopCouponRanking(code: 'SAVE5', usedCount: 3, fraction: 1.0),
    );

    await tester.tap(find.text('SAVE5'));
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/overview/admin_overview_state.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/top_product_tile.dart';

/// Pumps the tile under the app's localization delegates (it reads
/// `context.l10n` / `context.localizeDigits` / formats money per locale).
Widget wrap(Widget child, {Locale? locale}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

TopProductRanking ranking({String? nameAr}) => TopProductRanking(
      name: 'Classic Tee',
      nameAr: nameAr,
      unitsSold: 3,
      revenueCents: 4500,
    );

void main() {
  testWidgets('shows the name, units plural, and revenue',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(TopProductTile(ranking: ranking())));

    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text('3 units'), findsOneWidget);
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
  });

  testWidgets('singular units pluralize correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(TopProductTile(
      ranking: TopProductRanking(name: 'Tee', unitsSold: 1, revenueCents: 1500),
    )));

    expect(find.text('1 unit'), findsOneWidget);
  });

  testWidgets('Arabic renders the localized name and Eastern digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      TopProductTile(ranking: ranking(nameAr: 'تيشيرت كلاسيك')),
      locale: const Locale('ar'),
    ));

    // The Arabic snapshot label wins; the count and amount convert (the
    // exact currency shape carries bidi marks, so assert the digits part).
    expect(find.text('تيشيرت كلاسيك'), findsOneWidget);
    expect(find.text('٣ وحدات'), findsOneWidget);
    expect(find.textContaining('٤٥.٠٠'), findsOneWidget);
    expect(find.text('Classic Tee'), findsNothing);
    expect(find.text('3 units'), findsNothing);
  });

  testWidgets('falls back to the English name when no Arabic label exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      TopProductTile(ranking: ranking()),
      locale: const Locale('ar'),
    ));

    expect(find.text('Classic Tee'), findsOneWidget);
  });
}

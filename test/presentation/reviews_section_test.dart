import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/reviews_section.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// Pumps [ReviewsSection] standalone (the coupon_list_test pattern) on a
/// seeded memory DB, so the locale can be set directly on the MaterialApp.
///
/// Seeded 'Classic Tee' carries four approved reviews (5,5,4,4 → avg 4.5)
/// plus one hidden (pending) review that must NOT appear on the storefront.
void main() {
  late AppDatabase db;
  late int teeId;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  Future<void> seedAndPump(WidgetTester tester, {Locale? locale}) async {
    await tester.runAsync(() async {
      await getIt<SeedData>().seedIfNeeded();
      teeId = (await (db.select(db.products)
                ..where((t) => t.name.equals('Classic Tee')))
              .getSingle())
          .id;
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [ReviewsSection(productId: teeId)],
          ),
        ),
      ),
    );
    await settleDrift(tester); // the reviews watch stream
    await tester.pumpAndSettle();
  }

  testWidgets('shows the average, count, and only approved reviews',
      (WidgetTester tester) async {
    await seedAndPump(tester);

    // Average 4.5 (5+5+4+4 / 4) with the count.
    expect(find.text('4.5 / 5'), findsOneWidget);
    expect(find.text('4 reviews'), findsOneWidget);
    // Approved reviewers + comments render.
    for (final name in [
      'Amira Hassan',
      'Karim Adel',
      'Lina Fathy',
      'Omar Khaled',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Soft and true to size — my new favorite tee.'),
        findsOneWidget);
    // The hidden (pending) review is NOT on the storefront.
    expect(find.text('Runs small for me.'), findsNothing);
    expect(find.text('Sara Nabil'), findsNothing);

    await unmountApp(tester); // dispose the drift watch stream
  });

  testWidgets('Arabic: average and count use Eastern digits',
      (WidgetTester tester) async {
    await seedAndPump(tester, locale: const Locale('ar'));

    // Eastern digits with the Western decimal dot — the exact convention
    // money.formatCents pins (١٢.٣٤), so the average matches prices.
    expect(find.text('٤.٥ من ٥'), findsOneWidget);
    expect(find.text('٤ مراجعات'), findsOneWidget);
    expect(find.text('4.5 / 5'), findsNothing);

    await unmountApp(tester); // dispose the drift watch stream
  });

  testWidgets('write-review dialog: submit stays disabled until valid, then '
      'submits and confirms', (WidgetTester tester) async {
    await seedAndPump(tester);

    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('review-submit')), findsOneWidget);

    // Disabled: no rating and no name yet.
    final submit = tester.widget<FilledButton>(
      find.byKey(const Key('review-submit')),
    );
    expect(submit.onPressed, isNull);

    // Pick 4 stars + type a name + comment.
    await tester.tap(find.byKey(const Key('review-star-4')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('review-name')), 'Nour Ali');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('review-comment')),
      'Lovely fabric.',
    );
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('review-submit')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('review-submit')));
    await settleAction(tester, delay: const Duration(milliseconds: 200));

    // The success snackbar confirms, and the list still shows the approved
    // count (the new review is hidden pending approval).
    expect(find.text('Thank you! Your review will appear after approval.'),
        findsOneWidget);
    expect(find.text('4 reviews'), findsOneWidget);
    expect(find.text('Nour Ali'), findsNothing);

    // Flush the SnackBar timer, then dispose the drift watch stream (the
    // cleanup timer it schedules must fire before the test's end).
    await settleSnackBar(tester);
    await unmountApp(tester);
  });
}

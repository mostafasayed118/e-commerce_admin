import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/review.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/reviews/admin_reviews_state.dart';
import 'package:shop_admin/presentation/features/admin/reviews/widgets/review_list.dart';

Future<void> pumpList(
  WidgetTester tester, {
  required List<ProductReview> reviews,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReviewList(
            state: AdminReviewsLoaded(reviews: reviews),
            onSetApproved: (_, _) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

ProductReview review({
  int id = 1,
  int rating = 4,
  bool isApproved = false,
}) =>
    ProductReview(
      id: id,
      productId: 1,
      rating: rating,
      reviewerName: 'Ada',
      comment: 'Nice fit.',
      isApproved: isApproved,
      createdAt: DateTime(2026, 7, 1),
    );

void main() {
  testWidgets('renders reviewer, stars, comment, and status chip',
      (WidgetTester tester) async {
    await pumpList(tester, reviews: [review()]);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Nice fit.'), findsOneWidget);
    // Pending chip + Approve action (hidden review).
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    // The date renders (stable d MMM yyyy skeleton).
    expect(find.text('1 Jul 2026'), findsOneWidget);
    // The delete affordance is present.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('an approved review shows the Approved chip and Hide action',
      (WidgetTester tester) async {
    await pumpList(tester, reviews: [review(isApproved: true)]);

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
  });

  testWidgets('the empty state renders the moderation empty view',
      (WidgetTester tester) async {
    await pumpList(tester, reviews: []);

    expect(find.text('No reviews to moderate'), findsOneWidget);
    expect(find.text('Reviews submitted by customers will appear here.'),
        findsOneWidget);
  });

  testWidgets('stars reflect the rating', (WidgetTester tester) async {
    await pumpList(tester, reviews: [review(rating: 3)]);

    expect(
      find.byIcon(Icons.star),
      findsNWidgets(3),
    );
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });

  testWidgets('Arabic: the date converts to Eastern digits',
      (WidgetTester tester) async {
    await pumpList(tester, reviews: [review()], locale: const Locale('ar'));

    expect(find.text('١ يوليو ٢٠٢٦'), findsOneWidget);
    expect(find.text('قيد الانتظار'), findsOneWidget);
    expect(find.text('اعتماد'), findsOneWidget);
  });
}

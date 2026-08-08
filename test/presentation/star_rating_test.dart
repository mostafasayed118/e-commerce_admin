import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/widgets/star_rating.dart';

Future<void> pumpRating(WidgetTester tester, {required int rating}) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: StarRating(rating: rating))),
    );

void main() {
  testWidgets('fills exactly `rating` stars', (WidgetTester tester) async {
    await pumpRating(tester, rating: 4);

    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_border), findsNWidgets(1));
  });

  testWidgets('one star fills one', (WidgetTester tester) async {
    await pumpRating(tester, rating: 1);

    expect(find.byIcon(Icons.star), findsNWidgets(1));
    expect(find.byIcon(Icons.star_border), findsNWidgets(4));
  });

  testWidgets('five stars fill all', (WidgetTester tester) async {
    await pumpRating(tester, rating: 5);

    expect(find.byIcon(Icons.star), findsNWidgets(5));
    expect(find.byIcon(Icons.star_border), findsNothing);
  });
}

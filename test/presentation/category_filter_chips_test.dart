import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/category_filter_chips.dart';

/// Pumps the chip row under the app's localization delegates (it reads
/// `context.l10n` / `context.categoryName`).
Future<void> pumpChips(
  WidgetTester tester, {
  required List<Category> categories,
  int? selectedCategoryId,
  required ValueChanged<int?> onSelected,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CategoryFilterChips(
            categories: categories,
            selectedCategoryId: selectedCategoryId,
            onSelected: onSelected,
          ),
        ),
      ),
    );

const categories = [
  Category(id: 1, name: 'Clothing', nameAr: 'ملابس'),
  Category(id: 2, name: 'Books'),
];

void main() {
  testWidgets('the All chip is selected by default and the rest are not',
      (WidgetTester tester) async {
    await pumpChips(
      tester,
      categories: categories,
      selectedCategoryId: null,
      onSelected: (_) {},
    );

    final allChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'All'),
    );
    expect(allChip.selected, isTrue);

    final clothingChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Clothing'),
    );
    expect(clothingChip.selected, isFalse);
  });

  testWidgets('tapping a category reports its id', (WidgetTester tester) async {
    int? selected;
    await pumpChips(
      tester,
      categories: categories,
      selectedCategoryId: null,
      onSelected: (value) => selected = value,
    );

    await tester.tap(find.text('Clothing'));
    expect(selected, 1);

    await tester.tap(find.text('Books'));
    expect(selected, 2);
  });

  testWidgets('tapping All reports null (clear the filter)',
      (WidgetTester tester) async {
    int? selected = 1;
    await pumpChips(
      tester,
      categories: categories,
      selectedCategoryId: 1,
      onSelected: (value) => selected = value,
    );

    // With a category selected, the All chip is deselected and the category
    // chip carries the highlight.
    final allChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'All'),
    );
    expect(allChip.selected, isFalse);
    final clothingChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Clothing'),
    );
    expect(clothingChip.selected, isTrue);

    await tester.tap(find.text('All'));
    expect(selected, isNull);
  });

  testWidgets('Arabic renders the localized category names',
      (WidgetTester tester) async {
    await pumpChips(
      tester,
      categories: categories,
      selectedCategoryId: null,
      onSelected: (_) {},
      locale: const Locale('ar'),
    );

    expect(find.text('الكل'), findsOneWidget);
    // Clothing has an Arabic label; Books falls back to English.
    expect(find.text('ملابس'), findsOneWidget);
    expect(find.text('كتب'), findsNothing);
    expect(find.text('Books'), findsOneWidget);
  });
}

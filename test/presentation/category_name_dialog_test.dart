import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/category_name_dialog.dart';

/// Pumps a host Scaffold whose button opens the dialog and records the popped
/// record into [onResult].
Future<void> pumpDialog(
  WidgetTester tester, {
  required void Function(({String name, String? nameAr})? result) onResult,
  String? initial,
  String? initialAr,
  Locale? locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showDialog<({String name, String? nameAr})>(
                  context: context,
                  builder: (context) => CategoryNameDialog(
                    title: 'Rename category',
                    initial: initial ?? '',
                    initialAr: initialAr,
                    confirmLabel: 'Save',
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pre-fills the initial names and pops the entered record',
      (WidgetTester tester) async {
    ({String name, String? nameAr})? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      initial: 'Clothing',
      initialAr: 'ملابس',
    );

    // Both fields pre-fill from the initial values.
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('category-name-field')),
    );
    expect(nameField.controller!.text, 'Clothing');
    final arField = tester.widget<TextField>(
      find.byKey(const Key('category-name-ar-field')),
    );
    expect(arField.controller!.text, 'ملابس');

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      '  Shoes  ',
    );
    await tester.enterText(
      find.byKey(const Key('category-name-ar-field')),
      'أحذية',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The English name is trimmed; the Arabic one is kept.
    expect(result?.name, 'Shoes');
    expect(result?.nameAr, 'أحذية');
  });

  testWidgets('a blank Arabic name pops as null (English fallback)',
      (WidgetTester tester) async {
    ({String name, String? nameAr})? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      initial: 'Clothing',
    );

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Shoes',
    );
    // The Arabic field starts blank and stays blank.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result?.name, 'Shoes');
    expect(result?.nameAr, isNull);
  });

  testWidgets('cancel pops null', (WidgetTester tester) async {
    ({String name, String? nameAr})? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      initial: 'Clothing',
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('Arabic renders the localized field labels',
      (WidgetTester tester) async {
    await pumpDialog(
      tester,
      onResult: (_) {},
      initial: 'Clothing',
      locale: const Locale('ar'),
    );

    expect(find.text('اسم التصنيف'), findsOneWidget);
    expect(find.text('الاسم بالعربية (اختياري)'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
  });
}

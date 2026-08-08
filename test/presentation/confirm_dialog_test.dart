import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/widgets/confirm_dialog.dart';

/// Pumps a host Scaffold whose button awaits [showConfirmDialog] and records
/// the resolved value into [result].
Future<void> pumpDialog(
  WidgetTester tester, {
  required void Function(bool? result) onResult,
  required String title,
  required String message,
  String? confirmLabel,
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
                await showConfirmDialog(
                  context,
                  title: title,
                  message: message,
                  confirmLabel: confirmLabel,
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
  testWidgets('confirm resolves true with the localized default label',
      (WidgetTester tester) async {
    bool? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      title: 'Delete product?',
      message: 'It will be removed permanently.',
    );

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('cancel resolves false', (WidgetTester tester) async {
    bool? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      title: 'Delete product?',
      message: 'It will be removed permanently.',
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('a custom confirm label wins over the localized default',
      (WidgetTester tester) async {
    bool? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      title: 'Clear cart?',
      message: 'Every item will be removed.',
      confirmLabel: 'Clear',
    );

    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('Arabic resolves the default labels in Arabic',
      (WidgetTester tester) async {
    bool? result;
    await pumpDialog(
      tester,
      onResult: (value) => result = value,
      title: 'حذف المنتج؟',
      message: 'سيتم حذفه نهائيًا.',
      locale: const Locale('ar'),
    );

    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);

    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

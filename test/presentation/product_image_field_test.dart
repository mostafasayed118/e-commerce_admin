import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/services/image_store.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/product_image_field.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/product_image.dart';

/// Pumps the section with the app's localization delegates (it reads
/// `context.l10n` for the action labels).
Future<void> pumpField(
  WidgetTester tester,
  ProductImageField field, {
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: field),
      ),
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    // The preview thumb's ProductImage resolves paths through ImageStore,
    // so the non-null imagePath branches need one registered (an empty
    // temp dir is enough — the missing-file fallback is ProductImage's
    // own contract, pinned in product_image_test).
    tempDir = await Directory.systemTemp.createTemp('product_image_field_test');
    getIt.allowReassignment = true;
    getIt.registerSingleton<ImageStore>(
      ImageStore(documentsDirectory: () async => tempDir),
    );
    getIt.allowReassignment = false;
  });

  tearDown(() async {
    await getIt.reset();
    await tempDir.delete(recursive: true);
  });

  testWidgets('without an image shows only the add-image action',
      (WidgetTester tester) async {
    await pumpField(
      tester,
      ProductImageField(imagePath: null, picking: false, onPick: () {}, onRemove: () {}),
    );

    expect(find.text('Add image'), findsOneWidget);
    expect(find.text('Replace image'), findsNothing);
    expect(find.text('Remove image'), findsNothing);
    // The preview thumb renders the placeholder ProductImage.
    expect(find.byType(ProductImage), findsOneWidget);
  });

  testWidgets('with an image shows replace and remove actions',
      (WidgetTester tester) async {
    await pumpField(
      tester,
      ProductImageField(imagePath: 'tee.png', picking: false, onPick: () {}, onRemove: () {}),
    );

    expect(find.text('Add image'), findsNothing);
    expect(find.text('Replace image'), findsOneWidget);
    expect(find.text('Remove image'), findsOneWidget);
  });

  testWidgets('picking disables the primary action', (WidgetTester tester) async {
    await pumpField(
      tester,
      ProductImageField(imagePath: null, picking: true, onPick: () {}, onRemove: () {}),
    );

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('wires the pick and remove callbacks', (WidgetTester tester) async {
    var picked = false;
    var removed = false;
    await pumpField(
      tester,
      ProductImageField(
        imagePath: 'tee.png',
        picking: false,
        onPick: () => picked = true,
        onRemove: () => removed = true,
      ),
    );

    await tester.tap(find.text('Replace image'));
    expect(picked, isTrue);

    await tester.tap(find.text('Remove image'));
    expect(removed, isTrue);
  });

  testWidgets('Arabic: an image shows localized replace/remove labels',
      (WidgetTester tester) async {
    await pumpField(
      tester,
      ProductImageField(imagePath: 'tee.png', picking: false, onPick: () {}, onRemove: () {}),
      locale: const Locale('ar'),
    );

    expect(find.text('استبدال الصورة'), findsOneWidget);
    expect(find.text('إزالة الصورة'), findsOneWidget);
    expect(find.text('Replace image'), findsNothing);
  });

  testWidgets('Arabic: no image shows the localized add label',
      (WidgetTester tester) async {
    await pumpField(
      tester,
      ProductImageField(imagePath: null, picking: false, onPick: () {}, onRemove: () {}),
      locale: const Locale('ar'),
    );

    expect(find.text('إضافة صورة'), findsOneWidget);
    expect(find.text('Add image'), findsNothing);
  });
}

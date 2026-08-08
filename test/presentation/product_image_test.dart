import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/services/image_store.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/product_image.dart';

/// A real 1x1 transparent PNG, so Image.file decodes cleanly in the test.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  late Directory tempDir;
  late String relativePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('product_image_test');
    // ImageStore resolves relative paths against the documents dir; create
    // the file under `images/` so it matches a stored product's path.
    final imagesDir = Directory('${tempDir.path}${Platform.pathSeparator}images');
    await imagesDir.create(recursive: true);
    final file = File(
      '${imagesDir.path}${Platform.pathSeparator}tee.png',
    );
    await file.writeAsBytes(_pngBytes);
    relativePath = 'images${Platform.pathSeparator}tee.png';

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

  Future<void> pumpImage(WidgetTester tester, ProductImage image) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: image)));
    await tester.pump(); // let the FutureBuilder resolve fileFor
  }

  testWidgets('a null image path renders the placeholder icon',
      (WidgetTester tester) async {
    await pumpImage(tester, const ProductImage());

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a stored image path renders the file with a cover fit',
      (WidgetTester tester) async {
    await pumpImage(tester, ProductImage(imagePath: relativePath));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
  });

  testWidgets('a missing image file falls back to the placeholder',
      (WidgetTester tester) async {
    await pumpImage(tester, const ProductImage(imagePath: 'images/nope.png'));

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('honors the icon size on the placeholder',
      (WidgetTester tester) async {
    await pumpImage(tester, const ProductImage(iconSize: 64));

    final icon = tester.widget<Icon>(find.byIcon(Icons.image_outlined));
    expect(icon.size, 64);
  });
}

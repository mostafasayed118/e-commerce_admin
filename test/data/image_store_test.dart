import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/services/image_store.dart';

/// Pins ImageStore's file contract: saves copy into `<documents>/images/`
/// under a unique name and return the *relative* path (absolute paths must
/// never persist — the documents dir moves between runs); fileFor resolves a
/// relative path back; deletes are best-effort (a missing file is Success,
/// so an orphan never blocks a product update). The error mapping itself is
/// guardedResult's contract, pinned in guarded_result_test.
void main() {
  late Directory tempDir;
  late ImageStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_store_test');
    store = ImageStore(documentsDirectory: () async => tempDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<File> source(String name, [String content = 'x']) async {
    final srcDir = Directory('${tempDir.path}${Platform.pathSeparator}src');
    await srcDir.create(recursive: true);
    final file = File('${srcDir.path}${Platform.pathSeparator}$name');
    await file.writeAsString(content);
    return file;
  }

  test('saveImage copies the source into images/ and returns the relative path',
      () async {
    final src = await source('tee.png', 'PNGDATA');
    final result = await store.saveImage(src);
    final relative = (result as Success<String>).value;

    expect(relative, startsWith('images${Platform.pathSeparator}'));
    expect(relative, endsWith('.png'));

    // It's a copy, not a move: the source survives untouched.
    expect(await src.exists(), isTrue);
    expect(await src.readAsString(), 'PNGDATA');

    final stored = File('${tempDir.path}${Platform.pathSeparator}$relative');
    expect(await stored.exists(), isTrue);
    expect(await stored.readAsString(), 'PNGDATA');
  });

  test('two saves of the same source produce different (unique) paths',
      () async {
    final src = await source('tee.png');
    final first = (await store.saveImage(src)) as Success<String>;
    final second = (await store.saveImage(src)) as Success<String>;

    expect(first.value, isNot(second.value));
    expect(File('${tempDir.path}${Platform.pathSeparator}${first.value}').exists(),
        completion(isTrue));
    expect(File('${tempDir.path}${Platform.pathSeparator}${second.value}').exists(),
        completion(isTrue));
  });

  test('extensions are lowercased and a missing one defaults to .jpg',
      () async {
    final upper =
        (await store.saveImage(await source('pic.JPG'))) as Success<String>;
    expect(upper.value, endsWith('.jpg'));

    final none =
        (await store.saveImage(await source('noext'))) as Success<String>;
    expect(none.value, endsWith('.jpg'));
  });

  test('fileFor resolves a relative path against the documents dir',
      () async {
    // Use the platform separator end-to-end: the concatenation is verbatim.
    final relative = 'images${Platform.pathSeparator}tee.png';
    final file = await store.fileFor(relative);

    expect(file.path, '${tempDir.path}${Platform.pathSeparator}$relative');
  });

  test('deleteImage removes a stored file', () async {
    final relative =
        (await store.saveImage(await source('tee.png'))) as Success<String>;

    final result = await store.deleteImage(relative.value);

    expect(result, isA<Success<void>>());
    expect(
      File('${tempDir.path}${Platform.pathSeparator}${relative.value}').exists(),
      completion(isFalse),
    );
  });

  test('deleteImage on a missing file is Success (best-effort)', () async {
    final result = await store.deleteImage('images/never-existed.png');

    expect(result, isA<Success<void>>());
  });
}

import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../guarded_result.dart';

/// Owns product image files: picks are copied into `<documents>/images/` and
/// the *relative* path is what gets stored on [Product.imagePath] (the app
/// documents dir moves between runs, so absolute paths must never persist).
///
/// The documents-directory resolver is injectable so tests can point at a
/// temp directory instead of the platform channel.
class ImageStore {
  ImageStore({Future<Directory> Function()? documentsDirectory})
      : _documentsDirectory = documentsDirectory ?? _defaultDocuments;

  final Future<Directory> Function() _documentsDirectory;

  static Future<Directory> _defaultDocuments() async {
    return getApplicationDocumentsDirectory();
  }

  /// Copies [source] into `images/` under a unique name and returns the
  /// relative path (e.g. `images/1754..._12345.png`).
  Future<Result<String>> saveImage(File source) => guardedResult(
        () async {
          final imagesDir = await _ensureImagesDir();
          final name =
              '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 31)}${_extensionOf(source.path)}';
          await source.copy('${imagesDir.path}${Platform.pathSeparator}$name');
          return Success('images${Platform.pathSeparator}$name');
        },
        message: 'Could not save image',
        onError: (message, error) => ImageError(
          code: AppErrorCode.imageSave,
          message: message,
          cause: error,
        ),
      );

  /// Resolves a stored relative path to an absolute [File] for display.
  Future<File> fileFor(String relativePath) async {
    final documents = await _documentsDirectory();
    return File('${documents.path}${Platform.pathSeparator}$relativePath');
  }

  /// Deletes a stored image file (best-effort — orphans are harmless, so a
  /// missing file is Success, not an error).
  Future<Result<void>> deleteImage(String relativePath) => guardedResult(
        () async {
          final file = await fileFor(relativePath);
          if (await file.exists()) {
            await file.delete();
          }
          return const Success<void>(null);
        },
        message: 'Could not delete image',
        onError: (message, error) => ImageError(
          code: AppErrorCode.imageDelete,
          message: message,
          cause: error,
        ),
      );

  Future<Directory> _ensureImagesDir() async {
    final documents = await _documentsDirectory();
    final imagesDir =
        Directory('${documents.path}${Platform.pathSeparator}images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }
}

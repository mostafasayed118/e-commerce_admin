import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/guarded_result.dart';

/// Pins [guardedResult]'s contract, including the failure factory added for
/// the image store: exceptions become the default [DatabaseError] unless an
/// [onError] factory maps them to a different typed error, and early
/// non-throwing returns — including [Failure]s — pass through untouched.
void main() {
  test('successes pass through', () async {
    final result = await guardedResult(
      () async => const Success(42),
      message: 'no-op',
    );
    expect(result, isA<Success<int>>());
    expect((result as Success<int>).value, 42);
  });

  test('early Failures pass through untouched (never wrapped in DatabaseError)',
      () async {
    const notFound = NotFoundError(
      code: AppErrorCode.productNotFound,
      message: 'Product not found',
    );
    final result = await guardedResult(
      () async => const Failure<int>(notFound),
      message: 'Could not load product',
    );
    expect(result, isA<Failure<int>>());
    expect((result as Failure<int>).error, same(notFound));
  });

  test('a thrown Exception becomes a DatabaseError by default', () async {
    final result = await guardedResult<int>(
      () async => throw Exception('disk on fire'),
      message: 'Could not save widget',
    );
    expect(result, isA<Failure<int>>());
    final error = (result as Failure<int>).error;
    expect(error, isA<DatabaseError>());
    expect(error.code, AppErrorCode.database);
    expect(error.message, 'Could not save widget');
    expect(error.cause, isA<Exception>());
  });

  test('onError factory maps the exception to a custom typed failure',
      () async {
    final result = await guardedResult<String>(
      () async => throw Exception('bad file'),
      message: 'Could not save image',
      onError: (message, error) => ImageError(
        code: AppErrorCode.imageSave,
        message: message,
        cause: error,
      ),
    );
    expect(result, isA<Failure<String>>());
    final error = (result as Failure<String>).error;
    expect(error, isA<ImageError>());
    expect(error.code, AppErrorCode.imageSave);
    // The factory reuses guardedResult's message — no string of its own.
    expect(error.message, 'Could not save image');
    expect(error.cause, isA<Exception>());
  });
}

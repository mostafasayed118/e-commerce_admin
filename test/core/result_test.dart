import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';

void main() {
  group('Result', () {
    test('Success exposes isSuccess and the value', () {
      const result = Success<int>(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.getOrNull(), 42);
    });

    test('Failure exposes isFailure and the error', () {
      const error = ValidationError(
        code: AppErrorCode.quantityMin,
        message: 'nope',
      );
      const Failure<int> result = Failure<int>(error);
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.getOrNull(), isNull);
      expect(result.error, same(error));
    });

    test('fold destructures success without a cast', () {
      const result = Success<int>(7);
      final outcome = result.fold(
        onSuccess: (value) => 'value:$value',
        onFailure: (error) => 'error:${error.message}',
      );
      expect(outcome, 'value:7');
    });

    test('fold destructures failure without a cast', () {
      const result = Failure<int>(DatabaseError(message: 'disk'));
      final outcome = result.fold(
        onSuccess: (value) => 'value:$value',
        onFailure: (error) => 'error:${error.message}',
      );
      expect(outcome, 'error:disk');
    });

    test('getOrThrow returns the value on success', () {
      const result = Success<int>(1);
      expect(result.getOrThrow(), 1);
    });

    test('getOrThrow throws the AppError on failure', () {
      const result = Failure<int>(NotFoundError(
        code: AppErrorCode.productNotFound,
        message: 'missing',
      ));
      expect(() => result.getOrThrow(), throwsA(isA<NotFoundError>()));
    });

    test('preserves the value type across variants', () {
      const result = Success<String>('ok');
      expect(result, isA<Result<String>>());
    });
  });

  group('AppError', () {
    test('exposes message and cause', () {
      final cause = Exception('root cause');
      final error = DatabaseError(message: 'write failed', cause: cause);
      expect(error.message, 'write failed');
      expect(error.cause, same(cause));
    });

    test('toString includes the variant and message', () {
      const error = PinError(
        code: AppErrorCode.pinIncorrect,
        message: 'wrong pin',
      );
      expect(error.toString(), contains('PinError'));
      expect(error.toString(), contains('wrong pin'));
    });
  });
}

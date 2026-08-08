import 'dart:async';

import '../core/error/app_error.dart';
import '../core/error/result.dart';

/// Runs [action], mapping any thrown [Exception] to a [Failure] — the data
/// layer's exception→Result boundary (Section D.4) in one place instead of a
/// hand-rolled try/catch per operation.
///
/// By default the failure is a [DatabaseError] with [message] (the repository
/// boundary). Pass [onError] to build a different typed error — e.g.
/// [ImageError] for the image store — which reuses [message], so the factory
/// needs no string of its own.
///
/// Early non-throwing returns inside [action] (validation failures,
/// not-found results) pass through untouched; only exceptions become
/// failures.
Future<Result<T>> guardedResult<T>(
  Future<Result<T>> Function() action, {
  required String message,
  AppError Function(String message, Exception error)? onError,
}) async {
  try {
    return await action();
  } on Exception catch (error) {
    final failure =
        onError?.call(message, error) ??
        DatabaseError(message: message, cause: error);
    return Failure(failure);
  }
}

/// The not-found flavor of [guardedResult]: loads a row by id via [load]
/// and maps it through [map]; a `null` row becomes a typed [NotFoundError]
/// failure instead. Every CRUD `getById` shares this shape, so the
/// load → null-check → map scaffolding lives here rather than in each
/// repository.
Future<Result<T>> guardedLoadById<T, Row>(
  Future<Row?> Function() load, {
  required String message,
  required AppErrorCode notFoundCode,
  required String notFoundMessage,
  required FutureOr<T> Function(Row row) map,
}) =>
    guardedResult(
      () async {
        final row = await load();
        if (row == null) {
          return Failure(
            NotFoundError(code: notFoundCode, message: notFoundMessage),
          );
        }
        return Success(await map(row));
      },
      message: message,
    );

/// The affected-rows flavor of [guardedResult]: runs a write that reports
/// how many rows it touched ([write]); zero means the row was gone, which
/// becomes a typed [NotFoundError] failure. Used by the update/delete CRUD
/// operations whose DAO reports affected rows.
///
/// [onAffected] supplies the success value (the updated entity); delete
/// operations omit it — their success carries no value (`Success<void>`).
Future<Result<T>> guardedAffectedRows<T>(
  Future<int> Function() write, {
  required String message,
  required AppErrorCode notFoundCode,
  required String notFoundMessage,
  T Function()? onAffected,
}) =>
    guardedResult(
      () async {
        final affected = await write();
        if (affected == 0) {
          return Failure(
            NotFoundError(code: notFoundCode, message: notFoundMessage),
          );
        }
        // The void (delete) case: `null as T` is illegal for `T = void`, so
        // the value is smuggled through `dynamic` — the stored value is null
        // either way, matching the `Success<void>(null)` deletes returned.
        return onAffected == null
            ? Success<T>(null as dynamic)
            : Success(onAffected());
      },
      message: message,
    );

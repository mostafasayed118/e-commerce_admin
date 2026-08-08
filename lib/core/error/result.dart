import 'app_error.dart';
/// The project's result type: every repository operation returns a `Result<T>`
/// so callers must handle both the success and the failure path explicitly
/// (Section D.4 — no silent failures; errors are caught at the repository
/// boundary, never in Cubits or widgets).
///
/// [Success] carries the value, [Failure] carries a typed [AppError].
/// Because the type is sealed, exhaustive `switch` expressions let the
/// compiler verify every branch is handled.
sealed class Result<T> {
  const Result();
}

/// Successful outcome of an operation.
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// Failed outcome of an operation, carrying a typed [AppError].
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;
}

/// Convenience accessors used by Cubits and UseCases.
extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  /// Destructures the result without a cast. The workhorse for reading
  /// results — prefer it over `isSuccess` + field access.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }

  /// Returns the value, or `null` on failure. Mainly for tests and quick
  /// guards — prefer [fold] in production code.
  T? getOrNull() => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  /// Returns the value or throws the [AppError]. Use sparingly — the point
  /// of [Result] is to avoid throwing across layer boundaries.
  T getOrThrow() => switch (this) {
        Success(:final value) => value,
        Failure(:final error) => throw error,
      };

  /// Transforms the value on success; failures pass through unchanged.
  Result<R> map<R>(R Function(T value) onSuccess) => fold(
        onSuccess: (value) => Success(onSuccess(value)),
        onFailure: (error) => Failure(error),
      );

  /// Chains a synchronous [Result]-returning operation on success; failures
  /// pass through unchanged. Prefer over a hand-rolled `fold` with an
  /// `onFailure: (error) => Failure(error)` passthrough.
  Result<R> flatMap<R>(Result<R> Function(T value) onSuccess) => fold(
        onSuccess: onSuccess,
        onFailure: (error) => Failure(error),
      );

  /// Chains an asynchronous [Result]-returning operation on success; failures
  /// pass through unchanged. The composition workhorse for use cases that
  /// delegate one repository call, then run a rule on its value.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) onSuccess,
  ) async =>
      switch (this) {
        Success(:final value) => await onSuccess(value),
        Failure(:final error) => Failure(error),
      };
}

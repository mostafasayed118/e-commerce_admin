/// Typed application errors carried inside [Failure].
///
/// The data layer maps low-level exceptions (drift failures, file I/O, ...)
/// onto one of these variants; Cubits and widgets only ever see [AppError]s,
/// never raw exceptions. Add a variant when a new failure class appears.
sealed class AppError {
  const AppError({required this.message, this.cause});

  /// Human-readable message, safe to display to the user.
  final String message;

  /// The underlying exception, kept for debugging. Never log it verbatim if
  /// it could contain sensitive data (Section D.5).
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// A database/query operation failed (constraint violation, corrupt data, ...).
final class DatabaseError extends AppError {
  const DatabaseError({required super.message, super.cause});
}

/// Input violated a business rule (quantity exceeds stock, negative price, ...).
final class ValidationError extends AppError {
  const ValidationError({required super.message, super.cause});
}

/// The requested entity does not exist.
final class NotFoundError extends AppError {
  const NotFoundError({required super.message, super.cause});
}

/// Image picking or file storage failed.
final class ImageError extends AppError {
  const ImageError({required super.message, super.cause});
}

/// PIN/security related failure (wrong PIN, PIN not set, ...).
final class PinError extends AppError {
  const PinError({required super.message, super.cause});
}

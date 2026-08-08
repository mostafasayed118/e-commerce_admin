/// Stable, layer-agnostic error codes (Task 23 refactor).
///
/// The data/domain layers produce errors with a [AppErrorCode]; the
/// presentation layer maps each code to a localized string (see
/// presentation/l10n/error_messages.dart). The English [AppError.message]
/// remains for logs and developer tooling — it is no longer the UI's source
/// of truth. Codes that carry display data (product names, counts) are
/// handled by *typed variants* below, so the UI gets typed fields instead of
/// parsing strings.
enum AppErrorCode {
  /// Generic infrastructure failure (database, storage). Rare, not
  /// user-actionable — maps to a single "Something went wrong" style string.
  database,

  /// Product image save/delete failed.
  imageSave,
  imageDelete,

  // --- Not found ----------------------------------------------------------

  productNotFound,
  categoryNotFound,
  orderNotFound,
  cartProductUnavailable,

  // --- Validation / business rules ----------------------------------------

  /// Quantity must be at least 1.
  quantityMin,

  /// A product is out of stock (typed: [ProductOutOfStockError]).
  productOutOfStock,

  /// A cart quantity would exceed available stock (typed: [StockLimitError]).
  stockLimit,

  /// The cart is empty (order placement).
  cartEmpty,

  /// An illegal order-status transition was attempted.
  invalidStatusTransition,

  /// A category that still has products cannot be deleted
  /// (typed: [CategoryInUseError]).
  categoryInUse,

  // --- Coupons -----------------------------------------------------------

  /// The entered code does not match any coupon (typed: [CouponNotFoundError]).
  couponNotFound,

  /// The coupon exists but is disabled (typed: [CouponInactiveError]).
  couponInactive,

  /// The coupon's expiry date has passed (typed: [CouponExpiredError]).
  couponExpired,

  /// The order subtotal is below the coupon's minimum spend
  /// (typed: [CouponMinSpendError]).
  couponMinSpend,

  /// The coupon's usage cap is exhausted (typed: [CouponUsageLimitError]).
  couponUsageLimit,

  /// Admin tried to save a coupon whose code already exists.
  couponCodeTaken,

  nameRequired,
  phoneRequired,
  addressRequired,

  // --- PIN gate -----------------------------------------------------------

  pinFormat,
  pinNotSet,
  pinIncorrect,
}

/// Typed application errors carried inside [Failure].
///
/// The data layer maps low-level exceptions (drift failures, file I/O, ...)
/// onto one of these variants; Cubits and widgets only ever see [AppError]s,
/// never raw exceptions. Add a variant when a new failure class appears.
sealed class AppError {
  const AppError({required this.code, required this.message, this.cause});

  /// Stable code the UI maps to a localized message. The single source of
  /// truth for *what* failed; [message] is the developer-facing text.
  final AppErrorCode code;

  /// Human-readable message. Displayed directly only when a [code] has no
  /// localization (should not happen) — prefer mapping [code] in the UI.
  final String message;

  /// The underlying exception, kept for debugging. Never log it verbatim if
  /// it could contain sensitive data (Section D.5).
  final Object? cause;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// A database/query operation failed (constraint violation, corrupt data, ...).
/// All such failures map to [AppErrorCode.database] — the message keeps the
/// operation-specific detail for logs.
final class DatabaseError extends AppError {
  const DatabaseError({required super.message, super.cause})
      : super(code: AppErrorCode.database);
}

/// Input violated a business rule (quantity exceeds stock, negative price, ...).
/// Non-final: the data-carrying validation variants below extend it, so
/// `isA<ValidationError>()` matches them all (business-rule failures).
class ValidationError extends AppError {
  const ValidationError({
    required super.code,
    required super.message,
    super.cause,
  });
}

/// The requested entity does not exist.
final class NotFoundError extends AppError {
  const NotFoundError({required super.code, required super.message, super.cause});
}

/// Image picking or file storage failed.
final class ImageError extends AppError {
  const ImageError({required super.code, required super.message, super.cause});
}

/// PIN/security related failure (wrong PIN, PIN not set, ...).
final class PinError extends AppError {
  const PinError({required super.code, required super.message, super.cause});
}

/// Adding an out-of-stock product to the cart.
final class ProductOutOfStockError extends ValidationError {
  const ProductOutOfStockError({
    required this.productName,
    required super.message,
  }) : super(code: AppErrorCode.productOutOfStock);

  final String productName;
}

/// A cart quantity would exceed available stock. [currentInCart] feeds the
/// "(you have N in your cart)" hint (0 = no hint).
final class StockLimitError extends ValidationError {
  const StockLimitError({
    required this.productName,
    required this.stock,
    required this.currentInCart,
    required super.message,
  }) : super(code: AppErrorCode.stockLimit);

  final String productName;
  final int stock;
  final int currentInCart;
}

/// Deleting a category that still has products.
final class CategoryInUseError extends ValidationError {
  const CategoryInUseError({
    required this.productCount,
    required super.message,
  }) : super(code: AppErrorCode.categoryInUse);

  final int productCount;
}

/// The entered code does not match any coupon.
final class CouponNotFoundError extends ValidationError {
  const CouponNotFoundError({
    required this.couponCode,
    required super.message,
  }) : super(code: AppErrorCode.couponNotFound);

  final String couponCode;
}

/// The coupon exists but is disabled (isActive = false).
final class CouponInactiveError extends ValidationError {
  const CouponInactiveError({
    required this.couponCode,
    required super.message,
  }) : super(code: AppErrorCode.couponInactive);

  final String couponCode;
}

/// The coupon's expiry date has passed.
final class CouponExpiredError extends ValidationError {
  const CouponExpiredError({
    required this.couponCode,
    required super.message,
  }) : super(code: AppErrorCode.couponExpired);

  final String couponCode;
}

/// The order subtotal is below the coupon's minimum spend.
final class CouponMinSpendError extends ValidationError {
  const CouponMinSpendError({
    required this.couponCode,
    required this.requiredCents,
    required this.currentCents,
    required super.message,
  }) : super(code: AppErrorCode.couponMinSpend);

  final String couponCode;
  final int requiredCents;
  final int currentCents;
}

/// The coupon's usage cap is exhausted.
final class CouponUsageLimitError extends ValidationError {
  const CouponUsageLimitError({
    required this.couponCode,
    required this.maxUses,
    required super.message,
  }) : super(code: AppErrorCode.couponUsageLimit);

  final String couponCode;
  final int maxUses;
}

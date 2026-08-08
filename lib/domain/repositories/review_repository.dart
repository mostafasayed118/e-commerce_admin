import '../../core/entities/review.dart';
import '../../core/error/result.dart';

/// Read/write access to product reviews.
///
/// A storage gate (Decision A): the moderation rule (submissions start
/// hidden) is enforced by [addReview] forcing `isApproved: false`, and the
/// storefront read only exposes approved rows — a caller can neither submit
/// an approved review nor read a hidden one through this interface.
abstract interface class ReviewRepository {
  /// Approved reviews for [productId], newest first (the storefront read).
  /// The moderation filter is applied here, so UI code can never show a
  /// hidden review by accident.
  Stream<List<ProductReview>> watchApprovedForProduct(int productId);

  /// Every review, newest first (the admin moderation read).
  Stream<List<ProductReview>> watchAll();

  /// Stores a new review. The repository forces `isApproved: false` — the
  /// moderation gate at the data boundary — so a caller cannot bypass
  /// approval by submitting an approved review.
  Future<Result<ProductReview>> addReview(ProductReview draft);

  /// Flips a review's approval (the admin moderation action).
  Future<Result<ProductReview>> setApproved(int id, bool approved);

  Future<Result<void>> deleteReview(int id);
}

import '../../../core/entities/review.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../repositories/review_repository.dart';

/// Validates and submits a customer review (Decision A — the rule lives in
/// the use case, the repository stays a storage gate).
///
/// Rating must be 1-5 and the reviewer name non-blank; failures are typed
/// ([ReviewRatingInvalidError] / [ValidationError] with `nameRequired`), so
/// the dialog can map them to localized messages. The moderation gate (the
/// submitted review starts hidden) is enforced by the repository.
class AddReview {
  AddReview(this._reviews);

  final ReviewRepository _reviews;

  Future<Result<ProductReview>> call({
    required int productId,
    required int rating,
    required String reviewerName,
    String comment = '',
    DateTime? now,
  }) async {
    if (rating < 1 || rating > 5) {
      return Failure(ReviewRatingInvalidError(
        message: 'Rating must be between 1 and 5',
      ));
    }
    final name = reviewerName.trim();
    if (name.isEmpty) {
      return Failure(const ValidationError(
        code: AppErrorCode.nameRequired,
        message: 'Reviewer name is required',
      ));
    }
    return _reviews.addReview(ProductReview(
      id: 0,
      productId: productId,
      rating: rating,
      reviewerName: name,
      comment: comment.trim(),
      // isApproved defaults to false — the moderation gate, matching the
      // repository's forced write value.
      createdAt: now ?? DateTime.now(),
    ));
  }
}

import '../../../core/entities/review.dart';
// Row classes are generated in app_database.g.dart (part of app_database.dart).
import '../app_database.dart';

/// Assembles the [ProductReview] entity from a drift row. Mapping belongs in
/// the data layer (Section C.1) — entities never see drift types.
///
/// Writes go through companions built in the repository, so there is no
/// entity -> row mapping here (same decision as CouponMapper).
class ReviewMapper {
  ProductReview toEntity(ProductReviewRow row) {
    return ProductReview(
      id: row.id,
      productId: row.productId,
      rating: row.rating,
      reviewerName: row.reviewerName,
      comment: row.comment,
      isApproved: row.isApproved,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );
  }
}

import 'package:equatable/equatable.dart';

/// A customer's star rating + comment for a product.
///
/// Moderation contract (Decision A — rules in one place): new submissions
/// always start with [isApproved] = false — the repository forces it on
/// write — and only approved reviews are visible on the storefront (the
/// read stream filters on it). The admin moderation screen sees all rows.
class ProductReview extends Equatable {
  const ProductReview({
    required this.id,
    required this.productId,
    required this.rating,
    required this.reviewerName,
    this.comment = '',
    this.isApproved = false,
    this.createdAt,
  });

  final int id;
  final int productId;

  /// 1-5 stars.
  final int rating;
  final String reviewerName;
  final String comment;

  /// `false` until an admin approves (the moderation gate).
  final bool isApproved;
  final DateTime? createdAt;

  /// The only mutable field: the moderation flip. Everything else is fixed
  /// at submission time (a review is a snapshot, like an order line).
  ProductReview copyWith({bool? isApproved}) => ProductReview(
        id: id,
        productId: productId,
        rating: rating,
        reviewerName: reviewerName,
        comment: comment,
        isApproved: isApproved ?? this.isApproved,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        productId,
        rating,
        reviewerName,
        comment,
        isApproved,
        createdAt,
      ];
}

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'int_id_crud_mixin.dart';

part 'review_dao.g.dart';

/// Data access for review rows. Raw primitives only — the moderation rule
/// (submissions start hidden, only approved reviews reach the storefront)
/// lives in the repository/use case, never here.
@DriftAccessor(tables: [ProductReviews])
class ReviewDao extends DatabaseAccessor<AppDatabase>
    with
        _$ReviewDaoMixin,
        IntIdCrudDaoMixin<$ProductReviewsTable, ProductReviewRow,
            ProductReviewsCompanion> {
  ReviewDao(super.attachedDatabase);

  @override
  $ProductReviewsTable get table => productReviews;

  @override
  GeneratedColumn<int> get idColumn => productReviews.id;

  /// The storefront read: approved reviews for a product, newest first.
  /// The moderation filter lives HERE — the UI can never see a hidden
  /// review by accident, no matter what it calls.
  Stream<List<ProductReviewRow>> watchApprovedForProduct(int productId) {
    return (select(productReviews)
          ..where(
            (t) => t.productId.equals(productId) & t.isApproved.equals(true),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// The admin moderation read: every review, newest first.
  Stream<List<ProductReviewRow>> watchAll() {
    return (select(productReviews)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}

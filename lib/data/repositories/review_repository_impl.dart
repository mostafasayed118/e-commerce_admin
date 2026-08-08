import 'package:drift/drift.dart';

import '../../core/entities/review.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/review_repository.dart';
import '../database/app_database.dart';
import '../database/daos/review_dao.dart';
import '../database/mappers/review_mapper.dart';
import '../guarded_result.dart';

/// drift-backed [ReviewRepository].
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._dao, this._mapper);

  final ReviewDao _dao;
  final ReviewMapper _mapper;

  @override
  Stream<List<ProductReview>> watchApprovedForProduct(int productId) =>
      _dao.watchApprovedForProduct(productId).map(
            (rows) => rows.map(_mapper.toEntity).toList(),
          );

  @override
  Stream<List<ProductReview>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_mapper.toEntity).toList());

  @override
  Future<Result<ProductReview>> addReview(ProductReview draft) =>
      guardedResult(
        () async {
          final id = await _dao.insert(ProductReviewsCompanion.insert(
            productId: draft.productId,
            rating: draft.rating,
            reviewerName: draft.reviewerName,
            comment: Value(draft.comment),
            // The moderation gate: submissions are never auto-approved. A
            // draft's isApproved is deliberately ignored on write.
            isApproved: const Value(false),
            createdAt: draft.createdAt?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
          ));
          return getByIdOrFailure(id);
        },
        message: 'Could not save review',
      );

  @override
  Future<Result<ProductReview>> setApproved(int id, bool approved) =>
      guardedResult(
        () async {
          await _dao.updateById(
            id,
            ProductReviewsCompanion(isApproved: Value(approved)),
          );
          return getByIdOrFailure(id);
        },
        message: 'Could not update review',
      );

  @override
  Future<Result<void>> deleteReview(int id) => guardedResult(
        () async {
          await _dao.deleteById(id);
          return const Success<void>(null);
        },
        message: 'Could not delete review',
      );

  Future<Result<ProductReview>> getByIdOrFailure(int id) => guardedLoadById(
        () => _dao.getById(id),
        message: 'Could not load review',
        notFoundCode: AppErrorCode.reviewNotFound,
        notFoundMessage: 'Review not found',
        map: _mapper.toEntity,
      );
}

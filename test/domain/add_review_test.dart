import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/review.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/review_repository.dart';
import 'package:shop_admin/domain/usecases/reviews/add_review.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late MockReviewRepository repo;
  late AddReview useCase;

  setUpAll(() {
    registerFallbackValue(const ProductReview(
      id: 0,
      productId: 1,
      rating: 5,
      reviewerName: 'X',
    ));
  });

  setUp(() {
    repo = MockReviewRepository();
    useCase = AddReview(repo);
  });

  test('valid input delegates to the repository with a trimmed name',
      () async {
    when(() => repo.addReview(any()))
        .thenAnswer((_) async => const Success(ProductReview(
              id: 1,
              productId: 1,
              rating: 4,
              reviewerName: 'Ada',
            )));

    final result = await useCase(
      productId: 1,
      rating: 4,
      reviewerName: '  Ada  ',
      comment: '  Nice.  ',
    );

    expect(result.isSuccess, isTrue);
    final captured = verify(() => repo.addReview(captureAny()))
        .captured
        .single as ProductReview;
    expect(captured.reviewerName, 'Ada', reason: 'name is trimmed');
    expect(captured.comment, 'Nice.', reason: 'comment is trimmed');
    expect(captured.productId, 1);
    expect(captured.rating, 4);
    expect(captured.isApproved, isFalse,
        reason: 'submissions always start hidden');
  });

  test('a rating below 1 is rejected with the typed error', () async {
    final result = await useCase(
      productId: 1,
      rating: 0,
      reviewerName: 'Ada',
    );

    expect(result, isA<Failure<ProductReview>>());
    expect((result as Failure<ProductReview>).error,
        isA<ReviewRatingInvalidError>());
    expect(result.error.code, AppErrorCode.reviewRatingInvalid);
    verifyNever(() => repo.addReview(any()));
  });

  test('a rating above 5 is rejected', () async {
    final result = await useCase(
      productId: 1,
      rating: 6,
      reviewerName: 'Ada',
    );

    expect(result.isFailure, isTrue);
    expect((result as Failure<ProductReview>).error.code,
        AppErrorCode.reviewRatingInvalid);
  });

  test('a blank reviewer name is rejected', () async {
    final result = await useCase(
      productId: 1,
      rating: 5,
      reviewerName: '   ',
    );

    expect(result, isA<Failure<ProductReview>>());
    expect((result as Failure<ProductReview>).error.code,
        AppErrorCode.nameRequired);
    verifyNever(() => repo.addReview(any()));
  });
}

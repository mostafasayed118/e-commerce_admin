import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/review.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/review_repository.dart';
import 'package:shop_admin/presentation/features/admin/reviews/admin_reviews_cubit.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late MockReviewRepository repo;

  final review = const ProductReview(
    id: 1,
    productId: 1,
    rating: 4,
    reviewerName: 'Ada',
    isApproved: false,
  );

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
  });

  test('starts loading then emits the watched list', () async {
    when(() => repo.watchAll()).thenAnswer((_) => Stream.value([review]));
    final cubit = AdminReviewsCubit(repo);
    addTearDown(cubit.close);

    expect(cubit.state, isA<AdminReviewsLoading>());
    await pumpEventQueue();

    expect(cubit.state, isA<AdminReviewsLoaded>());
    expect((cubit.state as AdminReviewsLoaded).reviews, [review]);
  });

  test('a watch-stream error surfaces AdminReviewsError', () async {
    when(() => repo.watchAll()).thenAnswer((_) => Stream.error('boom'));
    final cubit = AdminReviewsCubit(repo);
    addTearDown(cubit.close);

    await pumpEventQueue();

    expect(cubit.state, isA<AdminReviewsError>());
  });

  test('setApproved delegates to the repository and returns its Result',
      () async {
    when(() => repo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => repo.setApproved(1, true)).thenAnswer(
      (_) async => Success(review.copyWith(isApproved: true)),
    );
    final cubit = AdminReviewsCubit(repo);
    addTearDown(cubit.close);

    final result = await cubit.setApproved(1, true);

    expect(result.isSuccess, isTrue);
    expect(result.getOrThrow().isApproved, isTrue);
    verify(() => repo.setApproved(1, true)).called(1);
  });

  test('deleteReview delegates to the repository', () async {
    when(() => repo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => repo.deleteReview(1))
        .thenAnswer((_) async => const Success<void>(null));
    final cubit = AdminReviewsCubit(repo);
    addTearDown(cubit.close);

    final result = await cubit.deleteReview(1);

    expect(result.isSuccess, isTrue);
    verify(() => repo.deleteReview(1)).called(1);
  });
}

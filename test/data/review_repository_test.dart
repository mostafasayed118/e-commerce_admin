import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/review.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/review_dao.dart';
import 'package:shop_admin/data/database/mappers/review_mapper.dart';
import 'package:shop_admin/data/repositories/review_repository_impl.dart';
import 'package:shop_admin/domain/repositories/review_repository.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ReviewRepositoryImpl(ReviewDao(db), ReviewMapper());
  });

  tearDown(() => db.close());

  /// Inserts a product (with its own category — names are unique per call
  /// so a test can insert several products).
  Future<int> insertProduct({String name = 'Tee'}) async {
    final categoryId = await db.into(db.categories).insert(
      CategoriesCompanion.insert(name: name, createdAt: 1),
    );
    return db.into(db.products).insert(
      ProductsCompanion.insert(
        categoryId: categoryId,
        name: name,
        priceCents: 2000,
        discountPercent: 0,
        stock: 5,
        createdAt: 1,
        updatedAt: 1,
      ),
    );
  }

  ProductReview draft({
    int productId = 1,
    int rating = 5,
    String reviewerName = 'Ada',
    String comment = 'Great.',
    DateTime? createdAt,
  }) =>
      ProductReview(
        id: 0,
        productId: productId,
        rating: rating,
        reviewerName: reviewerName,
        comment: comment,
        createdAt: createdAt,
      );

  test('addReview forces isApproved=false (the moderation gate)', () async {
    final productId = await insertProduct();

    // Even a draft that claims to be approved comes back hidden.
    final result = await repo.addReview(
      draft(productId: productId).copyWith(isApproved: true),
    );

    final review = result.getOrThrow();
    expect(review.id, greaterThan(0));
    expect(review.isApproved, isFalse);
    expect(review.rating, 5);
    expect(review.comment, 'Great.');
    expect(review.createdAt, isNotNull);
  });

  test('watchApprovedForProduct filters hidden reviews and re-emits on '
      'approval', () async {
    final productId = await insertProduct();
    // addReview always returns hidden; the "approved" one is flipped by the
    // moderator first, so the storefront stream starts with exactly it.
    // createdAt is staggered so the "newest first" order is deterministic
    // (two same-millisecond rows would tiebreak arbitrarily).
    final approved = (await repo.addReview(draft(
      productId: productId,
      createdAt: DateTime(2026, 7, 1),
    ))).getOrThrow();
    final hidden = (await repo.addReview(draft(
      productId: productId,
      rating: 2,
      comment: 'Hidden.',
      createdAt: DateTime(2026, 7, 2),
    ))).getOrThrow();
    await repo.setApproved(approved.id, true);
    expect(hidden.isApproved, isFalse);

    // The stream starts with the current state (only the approved review —
    // the newer hidden one is filtered), then re-emits after the flip with
    // both, newest first (hidden was created after approved).
    final done = expectLater(
      repo.watchApprovedForProduct(productId),
      emitsInOrder([
        isA<List<ProductReview>>().having(
          (r) => r.map((e) => e.id).toList(),
          'ids',
          [approved.id],
        ),
        isA<List<ProductReview>>().having(
          (r) => r.map((e) => e.id).toList(),
          'ids',
          [hidden.id, approved.id],
        ),
      ]),
    );
    await pumpEventQueue();
    await repo.setApproved(hidden.id, true);
    await done;
  });

  test('watchApprovedForProduct is scoped to the product', () async {
    final a = await insertProduct(name: 'Tee A');
    final b = await insertProduct(name: 'Tee B');
    await repo.addReview(draft(productId: a));

    final done = expectLater(
      repo.watchApprovedForProduct(b),
      emitsInOrder([isEmpty]),
    );
    await pumpEventQueue();
    await done;
  });

  test('setApproved flips a review both ways', () async {
    final productId = await insertProduct();
    final created =
        (await repo.addReview(draft(productId: productId))).getOrThrow();
    expect(created.isApproved, isFalse);

    final approved = (await repo.setApproved(created.id, true)).getOrThrow();
    expect(approved.isApproved, isTrue);
    // The flip persisted (a fresh read sees it).
    final watched = await repo.watchAll().first;
    expect(watched.single.isApproved, isTrue);

    final hiddenAgain =
        (await repo.setApproved(created.id, false)).getOrThrow();
    expect(hiddenAgain.isApproved, isFalse);
  });

  test('setApproved on a missing review is a not-found failure', () async {
    final result = await repo.setApproved(999, true);
    expect(result.isFailure, isTrue);
  });

  test('deleteReview removes the row', () async {
    final productId = await insertProduct();
    final created =
        (await repo.addReview(draft(productId: productId))).getOrThrow();

    expect((await repo.deleteReview(created.id)).isSuccess, isTrue);
    final watched = await repo.watchAll().first;
    expect(watched, isEmpty);
  });

  test('watchAll emits every review regardless of approval', () async {
    final productId = await insertProduct();
    await repo.addReview(draft(productId: productId));
    await repo.addReview(
      draft(productId: productId, rating: 2, comment: 'Hidden.'),
    );

    // The stream starts with the current state — both rows, approved or not.
    final done = expectLater(
      repo.watchAll(),
      emitsInOrder([hasLength(2)]),
    );
    await pumpEventQueue();
    await done;
  });

  test('deleting the product cascades its reviews (DB contract)', () async {
    final productId = await insertProduct();
    await repo.addReview(draft(productId: productId));

    await (db.delete(db.products)..where((t) => t.id.equals(productId))).go();

    expect(await repo.watchAll().first, isEmpty);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/domain/repositories/category_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/presentation/features/catalog/catalog_cubit.dart';
import 'package:shop_admin/presentation/features/catalog/catalog_sort.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockProductRepository productsRepo;
  late MockCategoryRepository categoriesRepo;
  late StreamController<List<Product>> productsCtrl;
  late StreamController<List<Category>> categoriesCtrl;
  late CatalogCubit cubit;

  const categories = [
    Category(id: 1, name: 'Clothing'),
    Category(id: 2, name: 'Electronics'),
  ];

  Product product({
    int id = 1,
    int categoryId = 1,
    String name = 'T-Shirt',
    String description = '',
    int priceCents = 2000,
    int discountPercent = 0,
    DateTime? createdAt,
  }) {
    return Product(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      priceCents: priceCents,
      discountPercent: discountPercent,
      stock: 10,
      createdAt: createdAt ?? DateTime(2026, 7, 1),
    );
  }

  void emitProducts(List<Product> list) => productsCtrl.add(list);
  void emitCategories(List<Category> list) => categoriesCtrl.add(list);

  setUp(() {
    productsRepo = MockProductRepository();
    categoriesRepo = MockCategoryRepository();
    productsCtrl = StreamController<List<Product>>.broadcast();
    categoriesCtrl = StreamController<List<Category>>.broadcast();
    when(() => productsRepo.watchProducts()).thenAnswer((_) => productsCtrl.stream);
    when(() => categoriesRepo.watchCategories())
        .thenAnswer((_) => categoriesCtrl.stream);
    cubit = CatalogCubit(productsRepo, categoriesRepo);
  });

  tearDown(() async {
    await cubit.close();
    await productsCtrl.close();
    await categoriesCtrl.close();
  });

  Future<void> settle() => pumpEventQueue();

  test('starts loading, then emits loaded once both streams emit', () async {
    expect(cubit.state, isA<CatalogLoading>());

    emitProducts([product()]);
    await settle();
    // Categories not yet emitted -> still loading.
    expect(cubit.state, isA<CatalogLoading>());

    emitCategories(categories);
    await settle();

    final state = cubit.state as CatalogLoaded;
    expect(state.products, hasLength(1));
    expect(state.categories, hasLength(2));
    expect(state.selectedCategoryId, isNull);
    expect(state.sort, CatalogSort.newest);
  });

  test('emits CatalogEmpty when there are no products at all', () async {
    emitProducts(const []);
    emitCategories(categories);
    await settle();

    expect(cubit.state, isA<CatalogEmpty>());
  });

  test('selectCategory filters the products', () async {
    emitProducts([
      product(id: 1, categoryId: 1, name: 'T-Shirt'),
      product(id: 2, categoryId: 2, name: 'Earbuds'),
    ]);
    emitCategories(categories);
    await settle();

    cubit.selectCategory(2);
    await settle();

    final state = cubit.state as CatalogLoaded;
    expect(state.products.map((p) => p.name), ['Earbuds']);
    expect(state.selectedCategoryId, 2);

    cubit.selectCategory(null);
    await settle();
    expect((cubit.state as CatalogLoaded).products, hasLength(2));
  });

  test('setQuery matches name and description, case-insensitively', () async {
    emitProducts([
      product(id: 1, name: 'Classic Tee'),
      product(id: 2, name: 'Wireless Earbuds', description: 'Crisp sound'),
    ]);
    emitCategories(categories);
    await settle();

    cubit.setQuery('earbuds');
    await settle();
    expect((cubit.state as CatalogLoaded).products.map((p) => p.name),
        ['Wireless Earbuds']);

    cubit.setQuery('CRISP');
    await settle();
    expect((cubit.state as CatalogLoaded).products, hasLength(1));

    cubit.setQuery('nope');
    await settle();
    final noMatch = cubit.state as CatalogLoaded;
    expect(noMatch.products, isEmpty);
    expect(noMatch.hasActiveFilter, isTrue);
  });

  test('setSort orders by final price', () async {
    emitProducts([
      product(id: 1, name: 'A', priceCents: 3000),
      product(id: 2, name: 'B', priceCents: 1000, discountPercent: 50),
      product(id: 3, name: 'C', priceCents: 2000),
    ]);
    emitCategories(categories);
    await settle();

    cubit.setSort(CatalogSort.priceAsc);
    await settle();

    // B: 1000 * 50% = 500; A: 3000; C: 2000 -> B, C, A.
    expect(
      (cubit.state as CatalogLoaded).products.map((p) => p.name).toList(),
      ['B', 'C', 'A'],
    );
  });

  test('newest sort falls back to a stable name tiebreak', () async {
    emitProducts([
      product(id: 1, name: 'Zeta', createdAt: DateTime(2026, 7, 1)),
      product(id: 2, name: 'Alpha', createdAt: DateTime(2026, 7, 1)),
    ]);
    emitCategories(categories);
    await settle();

    // Same createdAt -> alphabetical fallback.
    expect((cubit.state as CatalogLoaded).products.map((p) => p.name),
        ['Alpha', 'Zeta']);
  });

  test('a stream error surfaces as CatalogError', () async {
    emitCategories(categories);
    await settle();
    productsCtrl.addError(Exception('boom'));
    await settle();

    expect(cubit.state, isA<CatalogError>());
  });

  test('the error state is sticky: later emissions do not resurrect content',
      () async {
    emitProducts([product()]);
    emitCategories(categories);
    await settle();
    expect(cubit.state, isA<CatalogLoaded>());

    productsCtrl.addError(Exception('boom'));
    await settle();
    expect(cubit.state, isA<CatalogError>());

    // A later emission from the OTHER stream (or a user action) must not
    // override the error back to loaded.
    emitCategories(categories);
    cubit.setQuery('tee');
    await settle();
    expect(cubit.state, isA<CatalogError>());
  });

  test('close cancels the stream subscriptions', () async {
    final closed = cubit.close();
    // Broadcast controllers without listeners report no subscribers; the
    // cubit's listeners must have been cancelled by close().
    await settle();
    await closed;
    expect(productsCtrl.hasListener, isFalse);
    expect(categoriesCtrl.hasListener, isFalse);
  });
}

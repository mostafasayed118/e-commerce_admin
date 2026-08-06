import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/services/image_store.dart';
import 'package:shop_admin/domain/repositories/category_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/presentation/features/admin/catalog/admin_catalog_cubit.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockImageStore extends Mock implements ImageStore {}

void main() {
  // mocktail cannot fabricate non-nullable String/Category arguments for
  // any() — each non-nullable custom type needs a registered fallback.
  registerFallbackValue('');
  registerFallbackValue(const Category(id: 0, name: ''));

  late MockProductRepository products;
  late MockCategoryRepository categories;
  late MockImageStore images;
  late StreamController<List<Product>> productsCtrl;
  late StreamController<List<Category>> categoriesCtrl;

  const category = Category(id: 1, name: 'Clothing');
  const product = Product(
    id: 1,
    categoryId: 1,
    name: 'Classic Tee',
    priceCents: 2000,
    stock: 3,
    imagePath: 'images/a.png',
  );

  setUp(() {
    products = MockProductRepository();
    categories = MockCategoryRepository();
    images = MockImageStore();

    // Synchronous controllers: emissions land on the cubit's listeners
    // immediately, so assertions need no event-loop pumping.
    productsCtrl = StreamController<List<Product>>.broadcast(sync: true);
    categoriesCtrl = StreamController<List<Category>>.broadcast(sync: true);
    when(() => products.watchProducts()).thenAnswer((_) => productsCtrl.stream);
    when(() => categories.watchCategories())
        .thenAnswer((_) => categoriesCtrl.stream);
  });

  tearDown(() async {
    await productsCtrl.close();
    await categoriesCtrl.close();
  });

  group('watch streams', () {
    test('starts loading and emits loaded once both streams have emitted', () {
      final cubit = AdminCatalogCubit(products, categories, images);

      expect(cubit.state, isA<AdminCatalogLoading>());

      // Only one dataset so far — still loading.
      productsCtrl.add([product]);
      expect(cubit.state, isA<AdminCatalogLoading>());

      categoriesCtrl.add([category]);
      final loaded = cubit.state as AdminCatalogLoaded;
      expect(loaded.products, [product]);
      expect(loaded.categories, [category]);

      // Later emissions recompute and re-emit.
      productsCtrl.add([product, const Product(
        id: 2,
        categoryId: 1,
        name: 'Socks',
        priceCents: 500,
      )]);
      expect((cubit.state as AdminCatalogLoaded).products, hasLength(2));

      cubit.close();
    });

    test('a stream error becomes AdminCatalogError and is sticky', () {
      final cubit = AdminCatalogCubit(products, categories, images);
      productsCtrl.add([product]);
      categoriesCtrl.add([category]);
      expect(cubit.state, isA<AdminCatalogLoaded>());

      productsCtrl.addError(StateError('boom'));
      expect(cubit.state, isA<AdminCatalogError>());

      // A later emission from the *other* stream must NOT resurrect the
      // loaded state after an error (same sticky-error rule as CatalogCubit).
      categoriesCtrl.add([const Category(id: 2, name: 'Books')]);
      expect(cubit.state, isA<AdminCatalogError>());

      cubit.close();
    });

    test('close cancels the stream subscriptions', () async {
      final cubit = AdminCatalogCubit(products, categories, images);
      cubit.close();
      expect(productsCtrl.hasListener, isFalse);
      expect(categoriesCtrl.hasListener, isFalse);
    });
  });

  group('product CRUD', () {
    test('createProduct delegates to the repository and returns its result',
        () async {
      final cubit = AdminCatalogCubit(products, categories, images);
      const draft = Product(id: 0, categoryId: 1, name: 'New', priceCents: 999);
      when(() => products.createProduct(draft))
          .thenAnswer((_) async => const Success(draft));

      final result = await cubit.createProduct(draft);

      expect(result.isSuccess, isTrue);
      verify(() => products.createProduct(draft)).called(1);
      cubit.close();
    });

    test('updateProduct delegates to the repository', () async {
      final cubit = AdminCatalogCubit(products, categories, images);
      final updated = product.copyWith(stock: 42);
      when(() => products.updateProduct(updated))
          .thenAnswer((_) async => Success(updated));

      final result = await cubit.updateProduct(updated);

      expect(result.isSuccess, isTrue);
      verify(() => products.updateProduct(updated)).called(1);
      cubit.close();
    });

    test('deleteProduct cleans up the stored image file on success', () async {
      // Subscribe first: broadcast controllers drop emissions that arrive
      // before the cubit is listening.
      final cubit = AdminCatalogCubit(products, categories, images);
      productsCtrl.add([product]);
      categoriesCtrl.add([category]);

      when(() => products.deleteProduct(1))
          .thenAnswer((_) async => const Success<void>(null));
      when(() => images.deleteImage('images/a.png'))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await cubit.deleteProduct(1);

      expect(result.isSuccess, isTrue);
      verify(() => images.deleteImage('images/a.png')).called(1);
      cubit.close();
    });

    test('deleteProduct without an image never touches the ImageStore',
        () async {
      const noImage = Product(id: 2, categoryId: 1, name: 'Socks', priceCents: 500);
      final cubit = AdminCatalogCubit(products, categories, images);
      productsCtrl.add([noImage]);
      categoriesCtrl.add([category]);

      when(() => products.deleteProduct(2))
          .thenAnswer((_) async => const Success<void>(null));

      await cubit.deleteProduct(2);

      verifyNever(() => images.deleteImage(any()));
      cubit.close();
    });

    test('a failed delete leaves the image file alone', () async {
      final cubit = AdminCatalogCubit(products, categories, images);
      productsCtrl.add([product]);
      categoriesCtrl.add([category]);

      when(() => products.deleteProduct(1)).thenAnswer(
        (_) async => const Failure<void>(
          NotFoundError(
            code: AppErrorCode.productNotFound,
            message: 'gone',
          ),
        ),
      );

      final result = await cubit.deleteProduct(1);

      expect(result.isFailure, isTrue);
      verifyNever(() => images.deleteImage(any()));
      cubit.close();
    });
  });

  group('category CRUD', () {
    test('createCategory delegates with an id:0 draft', () async {
      final cubit = AdminCatalogCubit(products, categories, images);
      const created = Category(id: 7, name: 'Gadgets');
      when(() => categories.createCategory(any()))
          .thenAnswer((_) async => const Success(created));

      final result = await cubit.createCategory('Gadgets');

      expect(result.isSuccess, isTrue);
      verify(() => categories.createCategory(
        const Category(id: 0, name: 'Gadgets'),
      )).called(1);
      cubit.close();
    });

    test('updateCategory and deleteCategory delegate', () async {
      final cubit = AdminCatalogCubit(products, categories, images);
      final renamed = category.copyWith(name: 'Apparel');
      when(() => categories.updateCategory(renamed))
          .thenAnswer((_) async => Success(renamed));
      when(() => categories.deleteCategory(1))
          .thenAnswer((_) async => const Success<void>(null));

      expect((await cubit.updateCategory(renamed)).isSuccess, isTrue);
      expect((await cubit.deleteCategory(1)).isSuccess, isTrue);
      verify(() => categories.updateCategory(renamed)).called(1);
      verify(() => categories.deleteCategory(1)).called(1);
      cubit.close();
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/entities/wishlist_item.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/domain/repositories/wishlist_repository.dart';
import 'package:shop_admin/domain/usecases/wishlist/toggle_wishlist.dart';
import 'package:shop_admin/presentation/features/wishlist/wishlist_cubit.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockToggleWishlist extends Mock implements ToggleWishlist {}

void main() {
  late MockWishlistRepository wishlist;
  late MockProductRepository products;
  late MockToggleWishlist toggle;
  late StreamController<List<WishlistItem>> itemsCtrl;
  late StreamController<List<Product>> productsCtrl;

  const tee = Product(
    id: 1,
    categoryId: 1,
    name: 'Classic Tee',
    priceCents: 2000,
    discountPercent: 25,
    stock: 25,
  );

  setUp(() {
    wishlist = MockWishlistRepository();
    products = MockProductRepository();
    toggle = MockToggleWishlist();

    // Synchronous broadcast controllers: emissions land immediately, and
    // only after the cubit has subscribed (broadcast drops early emissions).
    itemsCtrl = StreamController<List<WishlistItem>>.broadcast(sync: true);
    productsCtrl = StreamController<List<Product>>.broadcast(sync: true);
    when(() => wishlist.watchWishlist()).thenAnswer((_) => itemsCtrl.stream);
    when(() => products.watchProducts()).thenAnswer((_) => productsCtrl.stream);
  });

  tearDown(() async {
    await itemsCtrl.close();
    await productsCtrl.close();
  });

  WishlistCubit buildCubit() => WishlistCubit(wishlist, products, toggle);

  group('watch streams', () {
    test('starts loading and emits loaded once both streams have emitted',
        () {
      final cubit = buildCubit();
      expect(cubit.state, isA<WishlistLoading>());

      itemsCtrl.add(const [WishlistItem(productId: 1)]);
      expect(cubit.state, isA<WishlistLoading>()); // products not emitted yet

      productsCtrl.add(const [tee]);
      final loaded = cubit.state as WishlistLoaded;
      expect(loaded.lines, hasLength(1));
      expect(loaded.lines.single.product, tee);
      expect(loaded.itemCount, 1);

      cubit.close();
    });

    test('an empty wishlist is a loaded state with zero items (not an error)',
        () {
      final cubit = buildCubit();
      itemsCtrl.add(const []);
      productsCtrl.add(const [tee]);

      final loaded = cubit.state as WishlistLoaded;
      expect(loaded.lines, isEmpty);
      expect(loaded.itemCount, 0);

      cubit.close();
    });

    test('wishlist rows for deleted products are skipped, not shown', () {
      final cubit = buildCubit();
      itemsCtrl.add(const [
        WishlistItem(productId: 1),
        WishlistItem(productId: 99), // product no longer exists
      ]);
      productsCtrl.add(const [tee]);

      final loaded = cubit.state as WishlistLoaded;
      expect(loaded.lines, hasLength(1));
      expect(loaded.itemCount, 1);

      cubit.close();
    });

    test('a stream error becomes WishlistError and is sticky', () {
      final cubit = buildCubit();
      itemsCtrl.add(const [WishlistItem(productId: 1)]);
      productsCtrl.add(const [tee]);
      expect(cubit.state, isA<WishlistLoaded>());

      itemsCtrl.addError(StateError('boom'));
      expect(cubit.state, isA<WishlistError>());

      // A later products emission must not resurrect the loaded state.
      productsCtrl.add(const [tee]);
      expect(cubit.state, isA<WishlistError>());

      cubit.close();
    });

    test('close cancels the stream subscriptions', () async {
      final cubit = buildCubit();
      cubit.close();
      expect(itemsCtrl.hasListener, isFalse);
      expect(productsCtrl.hasListener, isFalse);
    });
  });

  group('actions', () {
    test('toggle delegates to the use case', () async {
      final cubit = buildCubit();
      when(() => toggle(1))
          .thenAnswer((_) async => const Success<bool>(true));

      final result = await cubit.toggle(1);

      expect(result.isSuccess, isTrue);
      verify(() => toggle(1)).called(1);
      cubit.close();
    });
  });
}

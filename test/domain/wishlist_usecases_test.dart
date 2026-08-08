import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/cart_item.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/entities/wishlist_item.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/cart_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/domain/repositories/wishlist_repository.dart';
import 'package:shop_admin/domain/usecases/cart/add_to_cart.dart';
import 'package:shop_admin/domain/usecases/wishlist/move_wishlist_item_to_cart.dart';
import 'package:shop_admin/domain/usecases/wishlist/toggle_wishlist.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}

class MockCartRepository extends Mock implements CartRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockWishlistRepository wishlist;
  late ToggleWishlist toggle;

  setUpAll(() {
    // mocktail: any() on non-nullable int parameters needs a registered
    // fallback value.
    registerFallbackValue(0);
  });

  setUp(() {
    wishlist = MockWishlistRepository();
    toggle = ToggleWishlist(wishlist);
  });

  void mockContents(List<WishlistItem> items) {
    when(() => wishlist.watchWishlist())
        .thenAnswer((_) => Stream.value(items));
  }

  group('ToggleWishlist', () {
    test('adds a product that is not saved yet and reports it is saved',
        () async {
      mockContents(const []);
      when(() => wishlist.add(1))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await toggle(1);

      expect((result as Success<bool>).value, isTrue);
      verify(() => wishlist.add(1)).called(1);
      verifyNever(() => wishlist.remove(any()));
    });

    test('removes a product that is already saved and reports it is gone',
        () async {
      mockContents(const [WishlistItem(productId: 1)]);
      when(() => wishlist.remove(1))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await toggle(1);

      expect((result as Success<bool>).value, isFalse);
      verify(() => wishlist.remove(1)).called(1);
      verifyNever(() => wishlist.add(any()));
    });

    test('propagates add failures unchanged', () async {
      mockContents(const []);
      const dbError = DatabaseError(message: 'Could not save to wishlist');
      when(() => wishlist.add(1))
          .thenAnswer((_) async => const Failure<void>(dbError));

      final result = await toggle(1);

      expect(result, isA<Failure<bool>>());
      expect((result as Failure<bool>).error, same(dbError));
    });

    test('propagates remove failures unchanged', () async {
      mockContents(const [WishlistItem(productId: 1)]);
      const dbError =
          DatabaseError(message: 'Could not remove from wishlist');
      when(() => wishlist.remove(1))
          .thenAnswer((_) async => const Failure<void>(dbError));

      final result = await toggle(1);

      expect(result, isA<Failure<bool>>());
      expect((result as Failure<bool>).error, same(dbError));
    });
  });

  group('MoveWishlistItemToCart', () {
    late MockCartRepository cart;
    late MockProductRepository products;
    late MoveWishlistItemToCart move;

    const inStock = Product(
      id: 1,
      categoryId: 1,
      name: 'Classic Tee',
      priceCents: 2000,
      stock: 5,
    );
    const outOfStock = Product(
      id: 2,
      categoryId: 1,
      name: 'Leather Belt',
      priceCents: 2800,
      stock: 0,
    );

    setUp(() {
      cart = MockCartRepository();
      products = MockProductRepository();
      move = MoveWishlistItemToCart(
        AddToCart(cart, products),
        wishlist,
      );
    });

    test('adds to the cart and removes the saved item on success', () async {
      when(() => products.getById(any()))
          .thenAnswer((_) async => const Success(inStock));
      when(() => cart.watchCart()).thenAnswer(
        (_) => Stream.value(const <CartItem>[]),
      );
      when(() => cart.setQuantity(any(), any()))
          .thenAnswer((_) async => const Success<void>(null));
      when(() => wishlist.remove(1))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await move(1);

      expect(result, isA<Success<void>>());
      verify(() => cart.setQuantity(1, 1)).called(1);
      verify(() => wishlist.remove(1)).called(1);
    });

    test('a failed cart add leaves the wishlist entry intact', () async {
      when(() => products.getById(any()))
          .thenAnswer((_) async => const Success(outOfStock));

      final result = await move(2);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() => wishlist.remove(any()));
    });

    test('propagates a failed removal', () async {
      when(() => products.getById(any()))
          .thenAnswer((_) async => const Success(inStock));
      when(() => cart.watchCart()).thenAnswer(
        (_) => Stream.value(const <CartItem>[]),
      );
      when(() => cart.setQuantity(any(), any()))
          .thenAnswer((_) async => const Success<void>(null));
      const dbError =
          DatabaseError(message: 'Could not remove from wishlist');
      when(() => wishlist.remove(1))
          .thenAnswer((_) async => const Failure<void>(dbError));

      final result = await move(1);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, same(dbError));
    });
  });
}

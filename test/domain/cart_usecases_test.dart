import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/cart_item.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/cart_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/domain/usecases/cart/add_to_cart.dart';
import 'package:shop_admin/domain/usecases/cart/clear_cart.dart';
import 'package:shop_admin/domain/usecases/cart/remove_from_cart.dart';
import 'package:shop_admin/domain/usecases/cart/update_cart_quantity.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockCartRepository cart;
  late MockProductRepository products;
  late AddToCart addToCart;
  late UpdateCartQuantity updateQuantity;
  late RemoveFromCart removeFromCart;
  late ClearCart clearCart;

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

  setUpAll(() {
    // mocktail: any() on non-nullable int parameters needs a registered
    // fallback value.
    registerFallbackValue(0);
  });

  setUp(() {
    cart = MockCartRepository();
    products = MockProductRepository();
    addToCart = AddToCart(cart, products);
    updateQuantity = UpdateCartQuantity(cart, products);
    removeFromCart = RemoveFromCart(cart);
    clearCart = ClearCart(cart);
  });

  void mockProduct(Result<Product> result) {
    when(() => products.getById(any())).thenAnswer((_) async => result);
  }

  void mockCartContents(List<CartItem> items) {
    when(() => cart.watchCart()).thenAnswer((_) => Stream.value(items));
  }

  void mockSetQuantity(Result<void> result) {
    when(() => cart.setQuantity(any(), any())).thenAnswer((_) async => result);
  }

  group('AddToCart', () {
    test('adds an item not yet in the cart (target = current + quantity)',
        () async {
      mockProduct(const Success(inStock));
      mockCartContents(const []);
      mockSetQuantity(const Success<void>(null));

      final result = await addToCart(1);

      expect(result, isA<Success<void>>());
      verify(() => cart.setQuantity(1, 1)).called(1);
    });

    test('adds to the existing quantity', () async {
      mockProduct(const Success(inStock));
      mockCartContents(const [CartItem(productId: 1, quantity: 2)]);
      mockSetQuantity(const Success<void>(null));

      final result = await addToCart(1);

      expect(result, isA<Success<void>>());
      verify(() => cart.setQuantity(1, 3)).called(1);
    });

    test('rejects adding to an out-of-stock product without touching the cart',
        () async {
      mockProduct(const Success(outOfStock));

      final result = await addToCart(2);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() => cart.setQuantity(any(), any()));
    });

    test('rejects when the target would exceed stock (reject, don\'t clamp)',
        () async {
      mockProduct(const Success(inStock)); // stock 5
      mockCartContents(const [CartItem(productId: 1, quantity: 4)]);
      mockSetQuantity(const Success<void>(null));

      final result = await addToCart(1, quantity: 2);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() => cart.setQuantity(any(), any()));
    });

    test('allows landing exactly at the stock cap', () async {
      mockProduct(const Success(inStock)); // stock 5
      mockCartContents(const [CartItem(productId: 1, quantity: 4)]);
      mockSetQuantity(const Success<void>(null));

      final result = await addToCart(1); // target 5 == stock

      expect(result, isA<Success<void>>());
      verify(() => cart.setQuantity(1, 5)).called(1);
    });

    test('propagates NotFoundError for a missing product', () async {
      mockProduct(const Failure(NotFoundError(message: 'Product not found')));
      mockSetQuantity(const Success<void>(null));

      final result = await addToCart(999);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<NotFoundError>());
      verifyNever(() => cart.setQuantity(any(), any()));
    });

    test('propagates repository failures unchanged', () async {
      const dbError = DatabaseError(message: 'Could not load product');
      mockProduct(const Failure(dbError));

      final result = await addToCart(1);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, same(dbError));
    });

    test('rejects a non-positive quantity before any repository access',
        () async {
      final result = await addToCart(1, quantity: 0);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() => products.getById(any()));
      verifyNever(() => cart.setQuantity(any(), any()));
    });
  });

  group('UpdateCartQuantity', () {
    test('sets the absolute target quantity', () async {
      mockProduct(const Success(inStock));
      mockCartContents(const [CartItem(productId: 1, quantity: 2)]);
      mockSetQuantity(const Success<void>(null));

      final result = await updateQuantity(1, 3);

      expect(result, isA<Success<void>>());
      verify(() => cart.setQuantity(1, 3)).called(1);
    });

    test('rejects a raise above stock', () async {
      mockProduct(const Success(inStock)); // stock 5
      mockCartContents(const [CartItem(productId: 1, quantity: 4)]);
      mockSetQuantity(const Success<void>(null));

      final result = await updateQuantity(1, 6);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() => cart.setQuantity(any(), any()));
    });

    test('allows reducing when stock dropped below the current quantity',
        () async {
      // Admin cut stock to 2 while the cart holds 4: stepping down to 3 must
      // be allowed (the user is moving toward compliance), not trapped.
      mockProduct(const Success(Product(
        id: 1,
        categoryId: 1,
        name: 'Classic Tee',
        priceCents: 2000,
        stock: 2,
      )));
      mockCartContents(const [CartItem(productId: 1, quantity: 4)]);
      mockSetQuantity(const Success<void>(null));

      final result = await updateQuantity(1, 3);

      expect(result, isA<Success<void>>());
      verify(() => cart.setQuantity(1, 3)).called(1);
    });

    test('rejects a target below 1', () async {
      mockProduct(const Success(inStock));

      final result = await updateQuantity(1, 0);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
      verifyNever(() => cart.setQuantity(any(), any()));
    });

    test('propagates NotFoundError for a missing product', () async {
      mockProduct(const Failure(NotFoundError(message: 'Product not found')));

      final result = await updateQuantity(999, 1);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<NotFoundError>());
      verifyNever(() => cart.setQuantity(any(), any()));
    });
  });

  group('RemoveFromCart', () {
    test('forwards to the repository', () async {
      when(() => cart.removeItem(1))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await removeFromCart(1);

      expect(result, isA<Success<void>>());
      verify(() => cart.removeItem(1)).called(1);
    });

    test('propagates the repository result unchanged', () async {
      const dbError = DatabaseError(message: 'Could not remove item from cart');
      when(() => cart.removeItem(1))
          .thenAnswer((_) async => const Failure<void>(dbError));

      final result = await removeFromCart(1);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, same(dbError));
    });
  });

  group('ClearCart', () {
    test('forwards to the repository', () async {
      when(() => cart.clear()).thenAnswer((_) async => const Success<void>(null));

      final result = await clearCart();

      expect(result, isA<Success<void>>());
      verify(() => cart.clear()).called(1);
    });
  });
}

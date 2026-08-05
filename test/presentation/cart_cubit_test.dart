import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/cart_item.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/cart_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/domain/usecases/cart/clear_cart.dart';
import 'package:shop_admin/domain/usecases/cart/remove_from_cart.dart';
import 'package:shop_admin/domain/usecases/cart/update_cart_quantity.dart';
import 'package:shop_admin/presentation/features/cart/cart_cubit.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockUpdateCartQuantity extends Mock implements UpdateCartQuantity {}

class MockRemoveFromCart extends Mock implements RemoveFromCart {}

class MockClearCart extends Mock implements ClearCart {}

void main() {
  late MockCartRepository cart;
  late MockProductRepository products;
  late MockUpdateCartQuantity updateQuantity;
  late MockRemoveFromCart remove;
  late MockClearCart clear;
  late StreamController<List<CartItem>> itemsCtrl;
  late StreamController<List<Product>> productsCtrl;

  // Classic Tee: $20.00, 25% off → $15.00 final.
  const tee = Product(
    id: 1,
    categoryId: 1,
    name: 'Classic Tee',
    priceCents: 2000,
    discountPercent: 25,
    stock: 25,
  );

  setUp(() {
    cart = MockCartRepository();
    products = MockProductRepository();
    updateQuantity = MockUpdateCartQuantity();
    remove = MockRemoveFromCart();
    clear = MockClearCart();

    // Synchronous broadcast controllers: emissions land immediately, and
    // only after the cubit has subscribed (broadcast drops early emissions).
    itemsCtrl = StreamController<List<CartItem>>.broadcast(sync: true);
    productsCtrl = StreamController<List<Product>>.broadcast(sync: true);
    when(() => cart.watchCart()).thenAnswer((_) => itemsCtrl.stream);
    when(() => products.watchProducts()).thenAnswer((_) => productsCtrl.stream);
  });

  tearDown(() async {
    await itemsCtrl.close();
    await productsCtrl.close();
  });

  CartCubit buildCubit() => CartCubit(
        cart,
        products,
        updateQuantity,
        remove,
        clear,
      );

  group('watch streams', () {
    test('starts loading and emits loaded once both streams have emitted', () {
      final cubit = buildCubit();
      expect(cubit.state, isA<CartLoading>());

      itemsCtrl.add(const [CartItem(productId: 1, quantity: 2)]);
      expect(cubit.state, isA<CartLoading>()); // products not emitted yet

      productsCtrl.add(const [tee]);
      final loaded = cubit.state as CartLoaded;
      expect(loaded.lines, hasLength(1));
      expect(loaded.lines.single.product, tee);
      expect(loaded.lines.single.quantity, 2);

      cubit.close();
    });

    test('totals are computed with integer cents, discount included', () {
      final cubit = buildCubit();
      itemsCtrl.add(const [CartItem(productId: 1, quantity: 2)]);
      productsCtrl.add(const [tee]);

      final loaded = cubit.state as CartLoaded;
      // 2 × $20.00 = $40.00; savings 2 × $5.00 = $10.00; total $30.00.
      expect(loaded.subtotalCents, 4000);
      expect(loaded.discountCents, 1000);
      expect(loaded.totalCents, 3000);
      expect(loaded.itemCount, 2);

      cubit.close();
    });

    test('an empty cart is a loaded state with zero totals (not an error)', () {
      final cubit = buildCubit();
      itemsCtrl.add(const []);
      productsCtrl.add(const [tee]);

      final loaded = cubit.state as CartLoaded;
      expect(loaded.lines, isEmpty);
      expect(loaded.itemCount, 0);
      expect(loaded.totalCents, 0);

      cubit.close();
    });

    test('cart rows for deleted products are skipped, not shown', () {
      final cubit = buildCubit();
      itemsCtrl.add(const [
        CartItem(productId: 1, quantity: 2),
        CartItem(productId: 99, quantity: 1), // product no longer exists
      ]);
      productsCtrl.add(const [tee]);

      final loaded = cubit.state as CartLoaded;
      expect(loaded.lines, hasLength(1));
      expect(loaded.itemCount, 2); // only the surviving line counts

      cubit.close();
    });

    test('a stream error becomes CartError and is sticky', () {
      final cubit = buildCubit();
      itemsCtrl.add(const [CartItem(productId: 1, quantity: 1)]);
      productsCtrl.add(const [tee]);
      expect(cubit.state, isA<CartLoaded>());

      itemsCtrl.addError(StateError('boom'));
      expect(cubit.state, isA<CartError>());

      // A later products emission must not resurrect the loaded state.
      productsCtrl.add(const [tee]);
      expect(cubit.state, isA<CartError>());

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
    test('updateQuantity delegates to the use case', () async {
      final cubit = buildCubit();
      when(() => updateQuantity(1, 3))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await cubit.updateQuantity(1, 3);

      expect(result.isSuccess, isTrue);
      verify(() => updateQuantity(1, 3)).called(1);
      cubit.close();
    });

    test('removeItem delegates to the use case', () async {
      final cubit = buildCubit();
      when(() => remove(1))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await cubit.removeItem(1);

      expect(result.isSuccess, isTrue);
      verify(() => remove(1)).called(1);
      cubit.close();
    });

    test('clear delegates to the use case', () async {
      final cubit = buildCubit();
      when(() => clear()).thenAnswer((_) async => const Success<void>(null));

      final result = await cubit.clear();

      expect(result.isSuccess, isTrue);
      verify(() => clear()).called(1);
      cubit.close();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/order_repository.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/domain/usecases/checkout/place_order.dart';
import 'package:shop_admin/domain/usecases/checkout/validate_shipping.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockOrderRepository orders;
  late MockSettingsRepository settings;
  late PlaceOrder placeOrder;

  const shipping = ShippingInfo(
    name: 'Amira Hassan',
    phone: '0100 000 0001',
    address: '14 Nile St, Cairo',
  );

  setUpAll(() {
    // mocktail: any() on non-nullable ShippingInfo needs a registered
    // fallback value (same lesson as the int fallback in Task 10).
    registerFallbackValue(const ShippingInfo());
  });

  setUp(() {
    orders = MockOrderRepository();
    settings = MockSettingsRepository();
    placeOrder = PlaceOrder(orders, settings);
  });

  group('validateShipping', () {
    test('returns no errors for a complete form', () {
      expect(validateShipping(shipping), isEmpty);
    });

    test('flags every empty field', () {
      const empty = ShippingInfo();
      final errors = validateShipping(empty);
      expect(errors, hasLength(3));
      expect(errors[kShippingNameField], isNotNull);
      expect(errors[kShippingPhoneField], isNotNull);
      expect(errors[kShippingAddressField], isNotNull);
    });

    test('flags only the missing fields', () {
      const partial = ShippingInfo(name: 'Amira');
      final errors = validateShipping(partial);
      expect(errors.keys, containsAll([kShippingPhoneField, kShippingAddressField]));
      expect(errors, isNot(contains(kShippingNameField)));
    });

    test('treats whitespace-only input as empty', () {
      const blank = ShippingInfo(name: '   ', phone: ' \t ', address: '');
      final errors = validateShipping(blank);
      expect(errors, hasLength(3));
    });
  });

  group('PlaceOrder', () {
    const placed = Order(
      id: 1,
      orderNumber: 'ORD-000001',
      status: OrderStatus.pending,
      subtotalCents: 2000,
      discountCents: 0,
      totalCents: 2000,
      shipping: shipping,
    );

    test('validates the form before touching the repositories', () async {
      final result = await placeOrder(const ShippingInfo());

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, isA<ValidationError>());
      verifyNever(() => orders.placeOrder(any()));
      verifyNever(() => settings.updateProfile(any()));
    });

    test('places the order and saves the profile as pre-fill on success',
        () async {
      when(() => orders.placeOrder(shipping))
          .thenAnswer((_) async => const Success(placed));
      when(() => settings.updateProfile(shipping))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await placeOrder(shipping);

      expect(result, isA<Success<Order>>());
      expect(result.getOrThrow(), placed);
      verify(() => orders.placeOrder(shipping)).called(1);
      verify(() => settings.updateProfile(shipping)).called(1);
    });

    test('skips the profile save when saveProfile is false', () async {
      when(() => orders.placeOrder(shipping))
          .thenAnswer((_) async => const Success(placed));

      final result = await placeOrder(shipping, saveProfile: false);

      expect(result, isA<Success<Order>>());
      verifyNever(() => settings.updateProfile(any()));
    });

    test('propagates an order failure without saving the profile', () async {
      const dbError = DatabaseError(message: 'Could not place order');
      when(() => orders.placeOrder(shipping))
          .thenAnswer((_) async => const Failure<Order>(dbError));

      final result = await placeOrder(shipping);

      expect(result, isA<Failure<Order>>());
      expect((result as Failure<Order>).error, same(dbError));
      verifyNever(() => settings.updateProfile(any()));
    });

    test('a failed profile save does not undo a placed order', () async {
      when(() => orders.placeOrder(shipping))
          .thenAnswer((_) async => const Success(placed));
      when(() => settings.updateProfile(shipping))
          .thenAnswer((_) async =>
              const Failure<void>(DatabaseError(message: 'Could not save profile')));

      final result = await placeOrder(shipping);

      expect(result, isA<Success<Order>>(),
          reason: 'the order stands even if the convenience save fails');
      verify(() => settings.updateProfile(shipping)).called(1);
    });

    test('a throwing profile save never escapes the Result boundary',
        () async {
      when(() => orders.placeOrder(shipping))
          .thenAnswer((_) async => const Success(placed));
      when(() => settings.updateProfile(any())).thenThrow(Exception('boom'));

      final result = await placeOrder(shipping);

      expect(result, isA<Success<Order>>(),
          reason: 'an exception from the best-effort save must be swallowed');
    });

    test('trims input before placing and saving', () async {
      when(() => orders.placeOrder(any())).thenAnswer((_) async => const Success(placed));
      when(() => settings.updateProfile(any()))
          .thenAnswer((_) async => const Success<void>(null));

      final result = await placeOrder(
        const ShippingInfo(name: '  Amira  ', phone: ' 0100 ', address: ' St '),
      );

      expect(result, isA<Success<Order>>());
      final trimmed = const ShippingInfo(
        name: 'Amira',
        phone: '0100',
        address: 'St',
      );
      verify(() => orders.placeOrder(trimmed)).called(1);
      verify(() => settings.updateProfile(trimmed)).called(1);
    });
  });
}

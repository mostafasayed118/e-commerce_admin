import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/coupon_repository.dart';
import 'package:shop_admin/domain/usecases/coupons/apply_coupon.dart';

class MockCouponRepository extends Mock implements CouponRepository {}

void main() {
  late MockCouponRepository coupons;
  late ApplyCoupon applyCoupon;

  final now = DateTime(2026, 7, 15);
  final valid = Coupon(
    id: 1,
    code: 'SAVE10',
    type: CouponDiscountType.percent,
    value: 10,
  );

  setUp(() {
    coupons = MockCouponRepository();
    applyCoupon = ApplyCoupon(coupons);
  });

  group('ApplyCoupon', () {
    test('rejects an empty code without touching the repository', () async {
      final result = await applyCoupon('   ', 3000, now: now);

      expect(result, isA<Failure<CouponApplication>>());
      expect(
        (result as Failure<CouponApplication>).error,
        isA<CouponNotFoundError>(),
      );
      verifyNever(() => coupons.getByCode(any()));
    });

    test('rejects an unknown code with a typed error', () async {
      when(() => coupons.getByCode('NOPE'))
          .thenAnswer((_) async => const Success<Coupon?>(null));

      final result = await applyCoupon('nope', 3000, now: now);

      expect(result, isA<Failure<CouponApplication>>());
      expect(
        (result as Failure<CouponApplication>).error,
        isA<CouponNotFoundError>(),
      );
      verify(() => coupons.getByCode('NOPE')).called(1);
    });

    test('normalizes the code before the lookup', () async {
      when(() => coupons.getByCode('SAVE10'))
          .thenAnswer((_) async => Success<Coupon?>(valid));

      await applyCoupon('  SAVE10 ', 3000, now: now);

      verify(() => coupons.getByCode('SAVE10')).called(1);
    });

    test('returns the coupon and its discount for a valid code', () async {
      when(() => coupons.getByCode('SAVE10'))
          .thenAnswer((_) async => Success<Coupon?>(valid));

      final application = (await applyCoupon('save10', 3000, now: now))
          .getOrThrow();

      expect(application.coupon, valid);
      expect(application.discountCents, 300);
    });

    test('an inactive coupon is a typed failure', () async {
      final inactive = Coupon(
        id: 2,
        code: 'OFF',
        type: CouponDiscountType.percent,
        value: 10,
        isActive: false,
      );
      when(() => coupons.getByCode('OFF'))
          .thenAnswer((_) async => Success<Coupon?>(inactive));

      final result = await applyCoupon('OFF', 3000, now: now);

      expect(
        (result as Failure<CouponApplication>).error,
        isA<CouponInactiveError>(),
      );
    });

    test('a fixed coupon is capped at the subtotal', () async {
      final big = Coupon(
        id: 3,
        code: 'BIG',
        type: CouponDiscountType.fixed,
        value: 10000,
      );
      when(() => coupons.getByCode('BIG'))
          .thenAnswer((_) async => Success<Coupon?>(big));

      final application = (await applyCoupon('BIG', 3000, now: now))
          .getOrThrow();

      expect(application.discountCents, 3000, reason: 'never over the total');
    });

    test('propagates a repository failure', () async {
      when(() => coupons.getByCode('SAVE10')).thenAnswer(
        (_) async => const Failure<Coupon?>(DatabaseError(message: 'boom')),
      );

      final result = await applyCoupon('SAVE10', 3000, now: now);

      expect(result, isA<Failure<CouponApplication>>());
      expect(
        (result as Failure<CouponApplication>).error,
        isA<DatabaseError>(),
      );
    });
  });
}

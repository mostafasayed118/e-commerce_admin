import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/core/error/app_error.dart';

/// Pins [Coupon.applyTo] — the single validation rule shared by the checkout
/// preview and the placement re-validation — so the two call sites can never
/// drift apart (Decision A: rules in one place).
void main() {
  final now = DateTime(2026, 7, 15);

  Coupon percentCoupon({
    int value = 10,
    int minSpendCents = 0,
    DateTime? expiresAt,
    int? maxUses,
    int usedCount = 0,
    bool isActive = true,
  }) =>
      Coupon(
        id: 1,
        code: 'SAVE10',
        type: CouponDiscountType.percent,
        value: value,
        minSpendCents: minSpendCents,
        expiresAt: expiresAt,
        maxUses: maxUses,
        usedCount: usedCount,
        isActive: isActive,
      );

  group('discountFor', () {
    test('percent uses integer money math on the subtotal', () {
      final coupon = percentCoupon(value: 10);
      expect(coupon.discountFor(3000), 300);
      expect(coupon.discountFor(1500), 150);
    });

    test('percent floors to 0 on a tiny subtotal (never negative)', () {
      // 3 cents × 10% = 0.3 cents → integer division floors to 0¢. Still
      // "applied" (a valid check), just worth nothing — spec edge case.
      final coupon = percentCoupon(value: 10);
      expect(coupon.discountFor(3), 0);
      expect(coupon.applyTo(3, now: now), isA<CouponValid>());
    });

    test('fixed is capped at the subtotal so the total never goes negative',
        () {
      final coupon = Coupon(
        id: 1,
        code: 'FIXED',
        type: CouponDiscountType.fixed,
        value: 10000,
      );
      expect(coupon.discountFor(3000), 3000, reason: 'capped at subtotal');
      expect(coupon.discountFor(20000), 10000, reason: 'below the cap is full');
    });
  });

  group('applyTo', () {
    test('a valid percent coupon applies', () {
      final check = percentCoupon(value: 10).applyTo(3000, now: now);
      expect(check, isA<CouponValid>());
      expect((check as CouponValid).discountCents, 300);
    });

    test('a valid fixed coupon applies below the cap', () {
      final coupon = Coupon(
        id: 1,
        code: 'SAVE5',
        type: CouponDiscountType.fixed,
        value: 500,
      );
      final check = coupon.applyTo(3000, now: now);
      expect((check as CouponValid).discountCents, 500);
    });

    test('an inactive coupon is rejected', () {
      final check = percentCoupon(isActive: false).applyTo(3000, now: now);
      expect(check, isA<CouponInvalid>());
      expect((check as CouponInvalid).error, isA<CouponInactiveError>());
    });

    test('an expired coupon is rejected, including at the expiry instant', () {
      final past = percentCoupon(
        expiresAt: now.subtract(const Duration(days: 1)),
      ).applyTo(3000, now: now);
      expect((past as CouponInvalid).error, isA<CouponExpiredError>());

      // Boundary: expiresAt == now is already expired (`!now.isBefore(...)`).
      final instant =
          percentCoupon(expiresAt: now).applyTo(3000, now: now);
      expect((instant as CouponInvalid).error, isA<CouponExpiredError>());
    });

    test('a coupon with future expiry is valid', () {
      final future = percentCoupon(
        expiresAt: now.add(const Duration(days: 30)),
      ).applyTo(3000, now: now);
      expect(future, isA<CouponValid>());
    });

    test('an exhausted usage cap is rejected', () {
      final check =
          percentCoupon(maxUses: 1, usedCount: 1).applyTo(3000, now: now);
      expect(check, isA<CouponInvalid>());
      final error = (check as CouponInvalid).error;
      expect(error, isA<CouponUsageLimitError>());
      expect(
        error,
        isA<CouponUsageLimitError>().having((e) => e.maxUses, 'maxUses', 1),
      );
    });

    test('usage below the cap is valid', () {
      final check =
          percentCoupon(maxUses: 5, usedCount: 4).applyTo(3000, now: now);
      expect(check, isA<CouponValid>());
    });

    test('an unmet minimum spend is rejected with both amounts', () {
      final check = percentCoupon(minSpendCents: 5000).applyTo(3000, now: now);
      expect(check, isA<CouponInvalid>());
      final error = (check as CouponInvalid).error as CouponMinSpendError;
      expect(error.requiredCents, 5000);
      expect(error.currentCents, 3000);
    });

    test('an exactly-met minimum spend is valid', () {
      final check = percentCoupon(minSpendCents: 3000).applyTo(3000, now: now);
      expect(check, isA<CouponValid>());
    });

    test('checks run in the fixed order: active, expiry, usage, min spend', () {
      // Inactive wins over expired.
      final inactive = percentCoupon(
        isActive: false,
        expiresAt: now.subtract(const Duration(days: 1)),
      ).applyTo(3000, now: now);
      expect((inactive as CouponInvalid).error, isA<CouponInactiveError>());

      // Expired wins over usage.
      final expired = percentCoupon(
        expiresAt: now.subtract(const Duration(days: 1)),
        maxUses: 1,
        usedCount: 1,
      ).applyTo(3000, now: now);
      expect((expired as CouponInvalid).error, isA<CouponExpiredError>());

      // Usage wins over min spend.
      final used = percentCoupon(
        maxUses: 1,
        usedCount: 1,
        minSpendCents: 5000,
      ).applyTo(3000, now: now);
      expect((used as CouponInvalid).error, isA<CouponUsageLimitError>());
    });
  });

  group('isExpiredAt', () {
    test('uses the injected instant, inclusive of the expiry moment', () {
      final coupon = percentCoupon(expiresAt: DateTime(2026, 7, 1));
      expect(coupon.isExpiredAt(DateTime(2026, 6, 30)), isFalse);
      expect(coupon.isExpiredAt(DateTime(2026, 7, 1)), isTrue,
          reason: 'now == expiresAt is expired (same rule as applyTo)');
      expect(coupon.isExpiredAt(DateTime(2026, 8, 1)), isTrue);
    });

    test('a coupon without an expiry never expires', () {
      expect(percentCoupon().isExpiredAt(DateTime(2100, 1, 1)), isFalse);
    });

    test('isExpired delegates to isExpiredAt with the wall clock', () {
      final expired = percentCoupon(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.isExpired, isTrue);
      final valid = percentCoupon(
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(valid.isExpired, isFalse);
    });
  });

  group('copyWith', () {
    test('clears expiresAt and maxUses with the sentinel (null is explicit)',
        () {
      final coupon = percentCoupon(
        expiresAt: now,
        maxUses: 5,
      );
      final cleared = coupon.copyWith(expiresAt: null, maxUses: null);
      expect(cleared.expiresAt, isNull);
      expect(cleared.maxUses, isNull);
      // The source is untouched.
      expect(coupon.expiresAt, now);
      expect(coupon.maxUses, 5);
    });
  });
}

import '../../../core/entities/coupon.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../repositories/coupon_repository.dart';

/// Validates a code against the eligible subtotal and returns the coupon +
/// its discount — the checkout *preview*. The authoritative re-validation
/// happens inside [OrderRepository.placeOrder] (same [Coupon.applyTo] rule,
/// so the two can never disagree).
class ApplyCoupon {
  ApplyCoupon(this._coupons);

  final CouponRepository _coupons;

  Future<Result<CouponApplication>> call(
    String code,
    int subtotalCents, {
    DateTime? now,
  }) async {
    final normalized = normalizeCouponCode(code);
    if (normalized.isEmpty) {
      return Failure(CouponNotFoundError(
        couponCode: normalized,
        message: 'Coupon code is empty',
      ));
    }
    final result = await _coupons.getByCode(normalized);
    return result.flatMap((coupon) {
      if (coupon == null) {
        return Failure(CouponNotFoundError(
          couponCode: normalized,
          message: 'No coupon with code $normalized',
        ));
      }
      final check = coupon.applyTo(subtotalCents, now: now ?? DateTime.now());
      return switch (check) {
        CouponValid(:final discountCents) =>
          Success(CouponApplication(coupon: coupon, discountCents: discountCents)),
        CouponInvalid(:final error) => Failure(error),
      };
    });
  }
}

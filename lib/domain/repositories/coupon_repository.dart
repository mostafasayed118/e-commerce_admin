import '../../core/entities/coupon.dart';
import '../../core/error/result.dart';

/// Read/write access to promo codes.
///
/// A storage gate (Decision A): the validation rules live in
/// [Coupon.applyTo]; the repository only normalizes the code on write and
/// guards the unique-code invariant.
abstract interface class CouponRepository {
  /// Reactive coupons, newest first.
  Stream<List<Coupon>> watchCoupons();

  /// `null` when no coupon carries this code. Callers normalize before
  /// calling (the use cases uppercase + trim).
  Future<Result<Coupon?>> getByCode(String code);

  /// Creates the coupon. [Coupon.code] is normalized (uppercase, trimmed) by
  /// the repository; a duplicate code is a [ValidationError] with
  /// `couponCodeTaken` (pre-checked — the UNIQUE constraint is the backstop).
  Future<Result<Coupon>> createCoupon(Coupon draft);

  /// Updates all editable fields (code, type, value, limits, active). Same
  /// normalization + duplicate rule as create, excluding the coupon itself.
  Future<Result<Coupon>> updateCoupon(Coupon coupon);

  Future<Result<void>> deleteCoupon(int id);
}

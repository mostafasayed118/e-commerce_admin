import 'package:equatable/equatable.dart';

import '../error/app_error.dart';

/// How a coupon discounts an order: a percentage of the eligible subtotal,
/// or a fixed amount in cents (money stays integer cents, Decision C).
enum CouponDiscountType { percent, fixed }

/// The canonical storage/query form of a promo code: uppercase, trimmed.
/// Shared by the repository (write normalization) and the checkout use cases
/// (read normalization) so the rule cannot drift between the three sites.
String normalizeCouponCode(String code) => code.trim().toUpperCase();

/// The outcome of validating a coupon against an order subtotal.
sealed class CouponCheck {
  const CouponCheck();
}

/// The coupon is applicable: [discountCents] is the amount to subtract.
final class CouponValid extends CouponCheck {
  const CouponValid(this.discountCents);

  final int discountCents;
}

/// The coupon is not applicable, carrying the typed error to surface to the
/// UI (mapped from its stable code — same discipline as every other error).
final class CouponInvalid extends CouponCheck {
  const CouponInvalid(this.error);

  final AppError error;
}

/// A promo code. The business rules live here, in [applyTo], so the checkout
/// preview (ApplyCoupon) and the order placement re-validation can never
/// disagree (Decision A — rules in one place, repositories stay gates).
class Coupon extends Equatable {
  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minSpendCents = 0,
    this.expiresAt,
    this.maxUses,
    this.usedCount = 0,
    this.isActive = true,
    this.createdAt,
  });

  final int id;

  /// Normalized storage form (uppercase, trimmed).
  final String code;
  final CouponDiscountType type;

  /// Percent (1-100) when [type] is percent, else fixed cents (> 0).
  final int value;

  /// Minimum eligible spend in cents; 0 = no minimum.
  final int minSpendCents;

  /// `null` = never expires.
  final DateTime? expiresAt;

  /// Usage cap; `null` = unlimited.
  final int? maxUses;

  /// Incremented atomically with each order that applies this coupon.
  final int usedCount;
  final bool isActive;
  final DateTime? createdAt;

  /// Display helper for the admin list: expired at *now*. (The authoritative
  /// validity check is [applyTo], which takes an injectable `now`.)
  bool get isExpired => isExpiredAt(DateTime.now());

  /// Expired at the given instant (inclusive: `now == expiresAt` is expired).
  /// The injectable form keeps dashboard counts deterministic under tests.
  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !now.isBefore(expiresAt!);

  /// The discount for [subtotalCents]: percent floors with integer math;
  /// fixed is capped at the subtotal so the total can never go negative.
  int discountFor(int subtotalCents) => switch (type) {
        CouponDiscountType.percent => subtotalCents * value ~/ 100,
        CouponDiscountType.fixed =>
          value > subtotalCents ? subtotalCents : value,
      };

  /// The single validation rule (checks run in a fixed order):
  /// active → unexpired → usage remaining → minimum spend.
  ///
  /// [subtotalCents] is the *eligible* spend — the line-discounted subtotal,
  /// i.e. what the customer would pay before this coupon (documented in the
  /// plan; "minimum spend" never counts the coupon's own discount).
  CouponCheck applyTo(int subtotalCents, {required DateTime now}) {
    if (!isActive) {
      return CouponInvalid(CouponInactiveError(
        couponCode: code,
        message: 'Coupon $code is inactive',
      ));
    }
    if (expiresAt != null && !now.isBefore(expiresAt!)) {
      return CouponInvalid(CouponExpiredError(
        couponCode: code,
        message: 'Coupon $code has expired',
      ));
    }
    final cap = maxUses;
    if (cap != null && usedCount >= cap) {
      return CouponInvalid(CouponUsageLimitError(
        couponCode: code,
        maxUses: cap,
        message: 'Coupon $code has reached its usage limit',
      ));
    }
    if (subtotalCents < minSpendCents) {
      return CouponInvalid(CouponMinSpendError(
        couponCode: code,
        requiredCents: minSpendCents,
        currentCents: subtotalCents,
        message: 'Coupon $code requires a minimum spend',
      ));
    }
    return CouponValid(discountFor(subtotalCents));
  }

  static const Object _unset = Object();

  /// Sentinel-aware copyWith: [expiresAt] and [maxUses] can be cleared to
  /// null (the admin can remove an expiry or a usage cap), so they use the
  /// sentinel pattern (same as Category.nameAr).
  Coupon copyWith({
    String? code,
    CouponDiscountType? type,
    int? value,
    int? minSpendCents,
    Object? expiresAt = _unset,
    Object? maxUses = _unset,
    int? usedCount,
    bool? isActive,
  }) {
    assert(
      identical(expiresAt, _unset) ||
          expiresAt is DateTime? &&
              (identical(maxUses, _unset) || maxUses is int?),
      'expiresAt must be DateTime? and maxUses int? or omitted',
    );
    return Coupon(
      id: id,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minSpendCents: minSpendCents ?? this.minSpendCents,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
      maxUses: identical(maxUses, _unset) ? this.maxUses : maxUses as int?,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        type,
        value,
        minSpendCents,
        expiresAt,
        maxUses,
        usedCount,
        isActive,
        createdAt,
      ];
}

/// The outcome of applying a coupon at checkout: the coupon plus the discount
/// it contributes (in cents). The preview UI and the order snapshot both use
/// it.
class CouponApplication extends Equatable {
  const CouponApplication({required this.coupon, required this.discountCents});

  final Coupon coupon;
  final int discountCents;

  @override
  List<Object?> get props => [coupon, discountCents];
}

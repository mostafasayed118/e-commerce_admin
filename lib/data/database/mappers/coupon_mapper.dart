import '../../../core/entities/coupon.dart';
// Row classes are generated in app_database.g.dart (part of app_database.dart).
import '../app_database.dart';

/// Assembles the [Coupon] entity from a drift row. Mapping belongs in the
/// data layer (Section C.1) — entities never see drift types.
///
/// Writes go through companions built in the repository, so there is no
/// entity -> row mapping here (same decision as ProductMapper).
class CouponMapper {
  Coupon toEntity(CouponRow row) {
    return Coupon(
      id: row.id,
      code: row.code,
      type: row.discountType,
      value: row.value,
      minSpendCents: row.minSpendCents,
      expiresAt: row.expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.expiresAt!),
      maxUses: row.maxUses,
      usedCount: row.usedCount,
      isActive: row.isActive,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );
  }
}

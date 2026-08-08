import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'int_id_crud_mixin.dart';

part 'coupon_dao.g.dart';

/// Data access for coupon rows. Raw primitives only — the validation rules
/// live in [Coupon.applyTo] (domain), never here.
@DriftAccessor(tables: [Coupons])
class CouponDao extends DatabaseAccessor<AppDatabase>
    with
        _$CouponDaoMixin,
        IntIdCrudDaoMixin<$CouponsTable, CouponRow, CouponsCompanion> {
  CouponDao(super.attachedDatabase);

  @override
  $CouponsTable get table => coupons;

  @override
  GeneratedColumn<int> get idColumn => coupons.id;

  /// Reactive coupons, newest first.
  Stream<List<CouponRow>> watchAll() {
    return (select(coupons)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// `null` when no coupon carries this (already normalized) code.
  Future<CouponRow?> getByCode(String code) {
    return (select(coupons)..where((t) => t.code.equals(code)))
        .getSingleOrNull();
  }

  /// +1 to the usage counter. Called from inside the order placement
  /// transaction, so a coupon use and its order can never drift apart.
  Future<void> incrementUsedCount(int id) async {
    final row = await getById(id);
    if (row == null) return;
    await (update(coupons)..where((t) => t.id.equals(id)))
        .write(CouponsCompanion(usedCount: Value(row.usedCount + 1)));
  }
}

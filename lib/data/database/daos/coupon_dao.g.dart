// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_dao.dart';

// ignore_for_file: type=lint
mixin _$CouponDaoMixin on DatabaseAccessor<AppDatabase> {
  $CouponsTable get coupons => attachedDatabase.coupons;
  CouponDaoManager get managers => CouponDaoManager(this);
}

class CouponDaoManager {
  final _$CouponDaoMixin _db;
  CouponDaoManager(this._db);
  $$CouponsTableTableManager get coupons =>
      $$CouponsTableTableManager(_db.attachedDatabase, _db.coupons);
}

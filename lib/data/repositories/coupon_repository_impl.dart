import 'package:drift/drift.dart';

import '../../core/entities/coupon.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../database/app_database.dart';
import '../database/daos/coupon_dao.dart';
import '../database/mappers/coupon_mapper.dart';
import '../guarded_result.dart';

/// drift-backed [CouponRepository].
class CouponRepositoryImpl implements CouponRepository {
  CouponRepositoryImpl(this._dao, this._mapper);

  final CouponDao _dao;
  final CouponMapper _mapper;

  /// The typed duplicate-code failure, shared by create and update.
  static Failure<Coupon> _codeTaken(String code) =>
      const Failure<Coupon>(ValidationError(
        code: AppErrorCode.couponCodeTaken,
        message: 'Coupon code already exists',
      ));

  @override
  Stream<List<Coupon>> watchCoupons() =>
      _dao.watchAll().map((rows) => rows.map(_mapper.toEntity).toList());

  @override
  Future<Result<Coupon?>> getByCode(String code) => guardedResult(
        () async {
          final row = await _dao.getByCode(normalizeCouponCode(code));
          return Success(row == null ? null : _mapper.toEntity(row));
        },
        message: 'Could not load coupon',
      );

  @override
  Future<Result<Coupon>> createCoupon(Coupon draft) {
    final code = normalizeCouponCode(draft.code);
    return guardedResult(() async {
      final existing = await _dao.getByCode(code);
      if (existing != null) return _codeTaken(code);
      final id = await _dao.insert(CouponsCompanion.insert(
        code: code,
        discountType: draft.type,
        value: draft.value,
        minSpendCents: Value(draft.minSpendCents),
        expiresAt: Value(draft.expiresAt?.millisecondsSinceEpoch),
        maxUses: Value(draft.maxUses),
        isActive: Value(draft.isActive),
        createdAt: draft.createdAt?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      ));
      return getByIdOrFailure(id);
    }, message: 'Could not create coupon');
  }

  @override
  Future<Result<Coupon>> updateCoupon(Coupon coupon) {
    final code = normalizeCouponCode(coupon.code);
    return guardedResult(() async {
      final existing = await _dao.getByCode(code);
      // Duplicate check excludes the coupon being edited (same id).
      if (existing != null && existing.id != coupon.id) {
        return _codeTaken(code);
      }
      await _dao.updateById(
        coupon.id,
        CouponsCompanion(
          code: Value(code),
          discountType: Value(coupon.type),
          value: Value(coupon.value),
          minSpendCents: Value(coupon.minSpendCents),
          expiresAt: Value(coupon.expiresAt?.millisecondsSinceEpoch),
          maxUses: Value(coupon.maxUses),
          isActive: Value(coupon.isActive),
        ),
      );
      return getByIdOrFailure(coupon.id);
    }, message: 'Could not update coupon');
  }

  @override
  Future<Result<void>> deleteCoupon(int id) => guardedResult(
        () async {
          await _dao.deleteById(id);
          return const Success<void>(null);
        },
        message: 'Could not delete coupon',
      );

  Future<Result<Coupon>> getByIdOrFailure(int id) => guardedLoadById(
        () => _dao.getById(id),
        message: 'Could not load coupon',
        notFoundCode: AppErrorCode.couponNotFound,
        notFoundMessage: 'Coupon not found',
        map: _mapper.toEntity,
      );
}

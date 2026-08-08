import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/coupon.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/repositories/coupon_repository.dart';
import 'admin_coupons_state.dart';

export 'admin_coupons_state.dart';

/// Drives the admin coupons screen. Single watch stream (no join needed —
/// coupons stand alone); CRUD actions delegate to the repository (which owns
/// the Result boundary) and return the Result so the screen can pop on
/// success / show the error on failure. The watch stream then re-emits the
/// updated list automatically.
class AdminCouponsCubit extends Cubit<AdminCouponsState> {
  AdminCouponsCubit(this._coupons) : super(const AdminCouponsLoading()) {
    _subscribe();
  }

  final CouponRepository _coupons;

  StreamSubscription<List<Coupon>>? _sub;

  void _subscribe() {
    _sub = _coupons.watchCoupons().listen(
      (coupons) => emit(AdminCouponsLoaded(coupons: coupons)),
      onError: (Object error) {
        emit(const AdminCouponsError('Could not load coupons'));
      },
    );
  }

  // --- CRUD: delegate to the repository; Results feed the screen's actions.

  Future<Result<Coupon>> createCoupon(Coupon draft) =>
      _coupons.createCoupon(draft);

  Future<Result<Coupon>> updateCoupon(Coupon coupon) =>
      _coupons.updateCoupon(coupon);

  Future<Result<void>> deleteCoupon(int id) => _coupons.deleteCoupon(id);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

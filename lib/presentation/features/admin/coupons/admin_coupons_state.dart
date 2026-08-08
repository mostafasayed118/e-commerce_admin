import 'package:equatable/equatable.dart';

import '../../../../core/entities/coupon.dart';

/// Sealed admin coupons states.
sealed class AdminCouponsState extends Equatable {
  const AdminCouponsState();

  @override
  List<Object?> get props => [];
}

final class AdminCouponsLoading extends AdminCouponsState {
  const AdminCouponsLoading();
}

/// All coupons loaded. An empty [coupons] list is the normal fresh state —
/// the screen renders an empty view with the create action.
final class AdminCouponsLoaded extends AdminCouponsState {
  const AdminCouponsLoaded({required this.coupons});

  final List<Coupon> coupons;

  @override
  List<Object?> get props => [coupons];
}

final class AdminCouponsError extends AdminCouponsState {
  const AdminCouponsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

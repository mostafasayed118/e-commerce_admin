import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/message_view.dart';
import 'admin_coupons_cubit.dart';
import 'widgets/coupon_form.dart';

/// Admin create/edit screen for a coupon. Pushed on the root navigator by
/// CouponsScreen. Reads the coupon snapshot from the shared
/// [AdminCouponsCubit]'s loaded state — deep links to an unknown id resolve
/// to a "Coupon not found" view — then delegates the form to [CouponForm]
/// (`widgets/`).
class CouponFormScreen extends StatelessWidget {
  const CouponFormScreen({super.key, this.couponId});

  /// `null` → create mode; otherwise the id of the coupon being edited.
  final int? couponId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCouponsCubit>.value(
      value: getIt<AdminCouponsCubit>(),
      child: BlocBuilder<AdminCouponsCubit, AdminCouponsState>(
        builder: (context, state) => switch (state) {
          AdminCouponsLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          AdminCouponsError() => const Scaffold(
              body: ErrorView(),
            ),
          AdminCouponsLoaded() => _buildForm(context, state),
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, AdminCouponsLoaded state) {
    final coupon = couponId == null
        ? null
        : state.coupons.where((c) => c.id == couponId).firstOrNull;
    if (couponId != null && coupon == null) {
      return Scaffold(
        body: MessageView(
          icon: Icons.search_off,
          title: context.l10n.couponNotFoundView,
        ),
      );
    }
    return CouponForm(coupon: coupon);
  }
}

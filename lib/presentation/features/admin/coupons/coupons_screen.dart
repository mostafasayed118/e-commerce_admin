import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/coupon.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/snack_bar.dart';
import '../widgets/admin_fab.dart';
import 'admin_coupons_cubit.dart';
import 'widgets/coupon_list.dart';

/// Admin coupon management: list with status chips, create (FAB), edit (tap
/// row), delete (confirm dialog). Same shape as ProductsScreen; the list
/// lives in [CouponList] (`widgets/`), which stays presentational.
class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCouponsCubit>.value(
      value: getIt<AdminCouponsCubit>(),
      child: const _CouponsView(),
    );
  }
}

class _CouponsView extends StatelessWidget {
  const _CouponsView();

  Future<void> _confirmDelete(BuildContext context, Coupon coupon) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteCouponTitle,
      message: l10n.deleteCouponMessage(coupon.code),
    );
    if (!confirmed || !context.mounted) return;

    final result = await context.read<AdminCouponsCubit>().deleteCoupon(
          coupon.id,
        );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      // Success is silent — the watch stream re-emits the shorter list.
      onFailure: (error) => showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.couponsTitle)),
      floatingActionButton: AdminFab(
        branch: 'coupons',
        label: l10n.newCoupon,
        onPressed: () => context.push('/admin/coupons/new'),
      ),
      body: BlocBuilder<AdminCouponsCubit, AdminCouponsState>(
        builder: (context, state) => switch (state) {
          AdminCouponsLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminCouponsError() => const ErrorView(),
          AdminCouponsLoaded() => CouponList(
              state: state,
              onEdit: (coupon) =>
                  context.push('/admin/coupons/${coupon.id}/edit'),
              onDelete: (coupon) => _confirmDelete(context, coupon),
              onCreate: () => context.push('/admin/coupons/new'),
            ),
        },
      ),
    );
  }
}

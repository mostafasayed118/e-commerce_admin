import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/review.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/responsive/content_max_width.dart';
import '../../../widgets/snack_bar.dart';
import 'admin_reviews_cubit.dart';
import 'widgets/review_list.dart';

/// Admin review moderation: list with approve/hide toggle, delete (confirm
/// dialog). Same shape as CouponsScreen; the list lives in [ReviewList]
/// (`widgets/`), which stays presentational.
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  Future<void> _setApproved(BuildContext context, ProductReview review, bool approved) async {
    final result = await context.read<AdminReviewsCubit>().setApproved(
          review.id,
          approved,
        );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      // Success is silent — the watch stream re-emits the updated chip.
      onFailure: (error) => showErrorSnackBar(context, error),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductReview review) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteReviewTitle,
      message: l10n.deleteReviewMessage,
    );
    if (!confirmed || !context.mounted) return;

    final result = await context.read<AdminReviewsCubit>().deleteReview(
          review.id,
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
    return BlocProvider<AdminReviewsCubit>.value(
      value: getIt<AdminReviewsCubit>(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.reviewsTitle)),
        body: BlocBuilder<AdminReviewsCubit, AdminReviewsState>(
          builder: (context, state) => switch (state) {
            AdminReviewsLoading() =>
              const Center(child: CircularProgressIndicator()),
            AdminReviewsError() => const ErrorView(),
            AdminReviewsLoaded() => ContentMaxWidth(
              child: ReviewList(
                state: state,
                onSetApproved: (review, approved) =>
                    _setApproved(context, review, approved),
                onDelete: (review) => _confirmDelete(context, review),
              ),
            ),
          },
        ),
      ),
    );
  }
}

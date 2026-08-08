import 'package:flutter/material.dart';

import '../../../../../core/entities/review.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../../widgets/message_view.dart';
import '../../../../widgets/star_rating.dart';
import '../../../orders/order_date_format.dart';
import '../admin_reviews_state.dart';

/// The admin moderation list: every review with an approve/hide toggle and
/// delete. Purely presentational — the actions are delegated to the screen
/// through [onSetApproved] / [onDelete].
class ReviewList extends StatelessWidget {
  const ReviewList({
    super.key,
    required this.state,
    required this.onSetApproved,
    required this.onDelete,
  });

  final AdminReviewsLoaded state;
  final void Function(ProductReview review, bool approved) onSetApproved;
  final ValueChanged<ProductReview> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.reviews.isEmpty) {
      return MessageView(
        icon: Icons.rate_review_outlined,
        title: l10n.noReviewsPendingTitle,
        message: l10n.noReviewsPendingMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.reviews.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final review = state.reviews[index];
        final scheme = Theme.of(context).colorScheme;
        final (statusLabel, chipColor, chipBackground) = review.isApproved
            ? (
                l10n.reviewApproved,
                scheme.primary,
                scheme.primaryContainer,
              )
            : (
                l10n.reviewPending,
                scheme.tertiary,
                scheme.tertiaryContainer,
              );

        return ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: chipColor),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  StarRating(rating: review.rating),
                  if (review.createdAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      formatOrderDate(
                        review.createdAt!,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(review.comment),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => onSetApproved(review, !review.isApproved),
                child: Text(
                  review.isApproved ? l10n.hideReview : l10n.approveReview,
                ),
              ),
              IconButton(
                tooltip: l10n.deleteReviewTooltip,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(review),
              ),
            ],
          ),
        );
      },
    );
  }
}

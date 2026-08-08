import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/review.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/repositories/review_repository.dart';
import '../../../../domain/usecases/reviews/add_review.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/snack_bar.dart';
import '../../../widgets/star_rating.dart';
import '../../orders/order_date_format.dart';

/// The storefront reviews block: approved-only read stream (the moderation
/// filter lives in the repository/DAO), an average + count header, the
/// review tiles, and the write-review dialog.
///
/// Deliberately no dedicated Cubit: one read stream + one action (the same
/// shape ProductDetailScreen documents) — a state machine adds nothing here.
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key, required this.productId});

  final int productId;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _submitting = false;

  Future<void> _writeReview() async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (context) => const _WriteReviewDialog(),
    );
    if (draft == null || !mounted) return;

    setState(() => _submitting = true);
    final result = await getIt<AddReview>()(
      productId: widget.productId,
      rating: draft.rating,
      reviewerName: draft.reviewerName,
      comment: draft.comment,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (_) => showSuccessSnackBar(context, context.l10n.reviewSubmitted),
      onFailure: (error) => showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionHeader(context.l10n.reviewsTitle)),
            // Submitting disables the button so the dialog can't double-fire.
            TextButton.icon(
              onPressed: _submitting ? null : _writeReview,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(context.l10n.writeReview),
            ),
          ],
        ),
        StreamBuilder<List<ProductReview>>(
          stream: getIt<ReviewRepository>()
              .watchApprovedForProduct(widget.productId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(context.l10n.errorLoadFailed);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            final reviews = snapshot.data ?? const <ProductReview>[];
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  context.l10n.noReviewsMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }
            final average = reviews.fold<int>(
                  0,
                  (sum, review) => sum + review.rating,
                ) /
                reviews.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AverageRow(average: average, count: reviews.length),
                const SizedBox(height: 8),
                for (final review in reviews)
                  _ReviewTile(
                    review: review,
                    // The last tile doesn't need a divider.
                    divider: review != reviews.last,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The "4.5 / 5 · 4 reviews" summary line under the header.
class _AverageRow extends StatelessWidget {
  const _AverageRow({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formattedAverage = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    ).format(average);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Icon(Icons.star, size: 20, color: Colors.amber),
        const SizedBox(width: 4),
        // The ARB's literal "5" (the / 5 denominator) converts with the
        // rest — Eastern digits in ar, like every other number.
        Text(
          context.localizeDigits(l10n.averageRating(formattedAverage)),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 8),
        Text(
          context.localizeDigits(l10n.reviewCount(count)),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// One approved review: name, date, stars, and the comment.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.divider});

  final ProductReview review;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                review.reviewerName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (review.createdAt != null)
              Text(
                formatOrderDate(
                  review.createdAt!,
                  locale: Localizations.localeOf(context).languageCode,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        StarRating(rating: review.rating),
        const SizedBox(height: 4),
        if (review.comment.isNotEmpty)
          Text(review.comment, style: theme.textTheme.bodyMedium),
        if (divider) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}

/// The untyped dialog return value: the validated fields AddReview needs.
typedef _ReviewDraft = ({int rating, String reviewerName, String comment});

/// The write-review dialog: star picker, name, comment. Submit stays
/// disabled until the fields are valid, so the use case's typed errors are
/// the backstop, not the primary UX.
class _WriteReviewDialog extends StatefulWidget {
  const _WriteReviewDialog();

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  int _rating = 0;
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();

  bool get _canSubmit =>
      _rating > 0 && _nameController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      (
        rating: _rating,
        reviewerName: _nameController.text.trim(),
        comment: _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.writeReview),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reviewRatingLabel,
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    // Keyed so the dialog test can tap a specific star.
                    key: Key('review-star-$i'),
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('review-name'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.reviewNameLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('review-comment'),
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.reviewCommentLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('review-submit'),
          onPressed: _canSubmit ? _submit : null,
          child: Text(l10n.submitReview),
        ),
      ],
    );
  }
}

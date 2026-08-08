import 'package:equatable/equatable.dart';

import '../../../../core/entities/review.dart';

/// Sealed admin reviews states.
sealed class AdminReviewsState extends Equatable {
  const AdminReviewsState();

  @override
  List<Object?> get props => [];
}

final class AdminReviewsLoading extends AdminReviewsState {
  const AdminReviewsLoading();
}

/// Every review loaded (approved + pending — moderation sees all rows).
final class AdminReviewsLoaded extends AdminReviewsState {
  const AdminReviewsLoaded({required this.reviews});

  final List<ProductReview> reviews;

  @override
  List<Object?> get props => [reviews];
}

final class AdminReviewsError extends AdminReviewsState {
  const AdminReviewsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

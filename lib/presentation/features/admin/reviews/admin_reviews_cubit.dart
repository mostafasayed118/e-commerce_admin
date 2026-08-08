import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/review.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/repositories/review_repository.dart';
import 'admin_reviews_state.dart';

export 'admin_reviews_state.dart';

/// Drives the admin review moderation screen. Single watch stream (all
/// reviews, newest first); approve/hide + delete delegate to the repository
/// and return the Result so the screen can show the error on failure. The
/// watch stream then re-emits the updated list automatically.
class AdminReviewsCubit extends Cubit<AdminReviewsState> {
  AdminReviewsCubit(this._reviews) : super(const AdminReviewsLoading()) {
    _subscribe();
  }

  final ReviewRepository _reviews;

  StreamSubscription<List<ProductReview>>? _sub;

  void _subscribe() {
    _sub = _reviews.watchAll().listen(
      (reviews) => emit(AdminReviewsLoaded(reviews: reviews)),
      onError: (Object error) {
        emit(const AdminReviewsError('Could not load reviews'));
      },
    );
  }

  // --- Moderation: delegate to the repository; Results feed the screen.

  Future<Result<ProductReview>> setApproved(int id, bool approved) =>
      _reviews.setApproved(id, approved);

  Future<Result<void>> deleteReview(int id) => _reviews.deleteReview(id);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

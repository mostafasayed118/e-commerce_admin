import 'package:equatable/equatable.dart';

import '../../../core/entities/shipping_info.dart';
import '../../../core/error/app_error.dart';

/// Sealed profile states.
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The current profile plus the save-in-progress feedback.
///
/// An empty [profile] is the normal fresh-install state (nothing saved yet) —
/// the screen renders a blank form with a hint, not an error. [saveError] and
/// [justSaved] are the inline feedback under the form; they persist across
/// watch-stream emissions (the stream re-emits the row we just saved) and
/// are cleared at the start of the next save.
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    required this.saving,
    required this.saveError,
    required this.saveErrorCode,
    required this.justSaved,
  });

  final ShippingInfo profile;
  final bool saving;

  /// Developer-facing text for logs (kept for tooling); the screen renders
  /// [saveErrorCode], not this string, so failures localize (Task 23
  /// refactor).
  final String? saveError;

  /// Stable code the screen maps to a localized message.
  final AppErrorCode? saveErrorCode;
  final bool justSaved;

  @override
  List<Object?> get props =>
      [profile, saving, saveError, saveErrorCode, justSaved];
}

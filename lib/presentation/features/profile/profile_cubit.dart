import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/shipping_info.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/usecases/profile/save_profile.dart';

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
    required this.justSaved,
  });

  final ShippingInfo profile;
  final bool saving;
  final String? saveError;
  final bool justSaved;

  @override
  List<Object?> get props => [profile, saving, saveError, justSaved];
}

/// Drives the profile tab: the customer's saved shipping details.
///
/// Same single-stream pattern as the other feature cubits — watch the
/// profile, recompute on emission. Because the profile is shared with the
/// checkout (PlaceOrder saves it too), an emission here may originate from
/// *either* writer; the screen re-seeds its fields from whatever arrives.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._settings, this._saveProfile) : super(const ProfileLoading()) {
    _subscribe();
  }

  final SettingsRepository _settings;
  final SaveProfile _saveProfile;

  ShippingInfo? _profile; // null until the stream's first emission
  bool _failed = false;

  // Save feedback, preserved across recomputes (see ProfileLoaded doc).
  bool _saving = false;
  String? _saveError;
  bool _justSaved = false;

  StreamSubscription<ShippingInfo?>? _sub;

  void _subscribe() {
    _sub = _settings.watchProfile().listen(
      (profile) {
        _profile = profile ?? const ShippingInfo();
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const ProfileError('Could not load your profile'));
      },
    );
  }

  void _recompute() {
    if (_failed) return; // sticky error, as in the other feature cubits
    final profile = _profile;
    if (profile == null) return;
    emit(ProfileLoaded(
      profile: profile,
      saving: _saving,
      saveError: _saveError,
      justSaved: _justSaved,
    ));
  }

  /// Saves the profile. The screen gates on its form validators first; this
  /// delegates to [SaveProfile], which re-validates as the domain gate.
  Future<void> save(ShippingInfo profile) async {
    if (_saving) return; // ignore double-taps while a save is in flight
    _saveError = null;
    _justSaved = false;
    _saving = true;
    _recompute();

    try {
      final result = await _saveProfile(profile);
      result.fold(
        onSuccess: (_) => _justSaved = true,
        onFailure: (error) => _saveError = error.message,
      );
    } on Exception {
      // The repository returns Failures for storage errors, but a *throwing*
      // path must never wedge the Save button in the `saving` state — the
      // same defensive posture as PlaceOrder's best-effort profile save.
      _saveError = 'Could not save profile';
    } finally {
      _saving = false;
      _recompute();
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

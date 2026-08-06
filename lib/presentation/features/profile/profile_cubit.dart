import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/shipping_info.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/usecases/profile/save_profile.dart';
import 'profile_state.dart';

export 'profile_state.dart';

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
  AppErrorCode? _saveErrorCode;
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
      saveErrorCode: _saveErrorCode,
      justSaved: _justSaved,
    ));
  }

  /// Saves the profile. The screen gates on its form validators first; this
  /// delegates to [SaveProfile], which re-validates as the domain gate.
  Future<void> save(ShippingInfo profile) async {
    if (_saving) return; // ignore double-taps while a save is in flight
    _saveError = null;
    _saveErrorCode = null;
    _justSaved = false;
    _saving = true;
    _recompute();

    try {
      final result = await _saveProfile(profile);
      result.fold(
        onSuccess: (_) => _justSaved = true,
        onFailure: (error) {
          _saveError = error.message;
          _saveErrorCode = error.code;
        },
      );
    } on Exception {
      // The repository returns Failures for storage errors, but a *throwing*
      // path must never wedge the Save button in the `saving` state — the
      // same defensive posture as PlaceOrder's best-effort profile save.
      _saveError = 'Could not save profile';
      _saveErrorCode = AppErrorCode.database;
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

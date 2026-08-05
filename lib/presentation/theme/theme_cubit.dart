import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/result.dart';
import '../../domain/repositories/settings_repository.dart';

/// Holds the app's [ThemeMode] and persists it in the single-row [UiPrefs]
/// table (code `'light'`/`'dark'`/`'system'`), so the customer's choice
/// survives restarts.
///
/// Starts on [ThemeMode.system] (follows the OS), then applies the persisted
/// choice as soon as the prefs load. Writes are best-effort: a failed save
/// only loses the choice, never breaks the app.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._settings) : super(ThemeMode.system) {
    _restore();
  }

  final SettingsRepository _settings;

  /// True once the user has made a choice. The async restore must never
  /// clobber a user toggle that landed while the DB read was in flight.
  bool _userSet = false;

  Future<void> _restore() async {
    final result = await _settings.getUiPrefs();
    if (isClosed || _userSet) return;
    result.fold(
      onSuccess: (prefs) {
        final code = prefs.themeModeCode;
        if (code != null && (code == 'light' || code == 'dark')) {
          emit(_parse(code));
        }
      },
      // Default to system on failure — never crash startup over a pref.
      onFailure: (_) {},
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _userSet = true;
    emit(mode);
    // Best-effort persistence: the choice already applied in memory; a
    // failed write just means it won't survive the next restart.
    await _settings.updateUiPrefs(themeModeCode: mode.name);
  }

  ThemeMode _parse(String code) =>
      code == 'light' ? ThemeMode.light : ThemeMode.dark;
}

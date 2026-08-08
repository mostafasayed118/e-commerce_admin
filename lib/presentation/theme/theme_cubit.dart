import 'package:flutter/material.dart';

import '../../core/entities/ui_prefs.dart';
import '../../domain/repositories/settings_repository.dart';
import '../persisted_pref_cubit.dart';

/// Holds the app's [ThemeMode] and persists it in the single-row [UiPrefs]
/// table (code `'light'`/`'dark'`/`'system'`), so the customer's choice
/// survives restarts.
///
/// Starts on [ThemeMode.system] (follows the OS), then applies the persisted
/// choice as soon as the prefs load. Writes are best-effort: a failed save
/// only loses the choice, never breaks the app.
class ThemeCubit extends PersistedPrefCubit<ThemeMode> {
  ThemeCubit(SettingsRepository settings) : super(ThemeMode.system, settings);

  @override
  ThemeMode? storedValue(UiPrefs prefs) {
    final code = prefs.themeModeCode;
    if (code == 'light') return ThemeMode.light;
    if (code == 'dark') return ThemeMode.dark;
    return null;
  }

  Future<void> setThemeMode(ThemeMode mode) => applyChoice(
        mode,
        () => settings.updateUiPrefs(themeModeCode: mode.name),
      );
}

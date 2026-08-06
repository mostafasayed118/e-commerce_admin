import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/result.dart';
import '../../domain/repositories/settings_repository.dart';

/// Holds the app's [Locale] and persists it in the single-row [UiPrefs]
/// table (the BCP-47 code), so the customer's language survives restarts.
///
/// Defaults to English until the persisted code arrives; the MaterialApp
/// wires it straight into `locale`, which also drives RTL for `'ar'`.
///
/// The canonical list of supported locales lives on the generated
/// [AppLocalizations.supportedLocales] (used by MaterialApp and the Profile
/// switch) — the cubit deliberately does not duplicate it.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._settings) : super(const Locale('en')) {
    _restore();
  }

  final SettingsRepository _settings;

  /// True once the user has made a choice. The async restore must never
  /// clobber a user switch that landed while the DB read was in flight.
  bool _userSet = false;

  Future<void> _restore() async {
    final result = await _settings.getUiPrefs();
    if (isClosed || _userSet) return;
    result.fold(
      onSuccess: (prefs) {
        // Only 'ar' is a supported non-default; unknown codes (a future
        // locale, corruption) silently stay English.
        if (prefs.localeCode == 'ar') emit(const Locale('ar'));
      },
      // Default to English on failure — never crash startup over a pref.
      onFailure: (_) {},
    );
  }

  Future<void> setLocaleCode(String code) async {
    _userSet = true;
    emit(Locale(code));
    // Best-effort persistence, same contract as ThemeCubit.
    await _settings.updateUiPrefs(localeCode: code);
  }
}

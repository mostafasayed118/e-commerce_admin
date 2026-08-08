import 'package:flutter/widgets.dart';

import '../../core/entities/ui_prefs.dart';
import '../../domain/repositories/settings_repository.dart';
import '../persisted_pref_cubit.dart';

/// Holds the app's [Locale] and persists it in the single-row [UiPrefs]
/// table (the BCP-47 code), so the customer's language survives restarts.
///
/// Defaults to English until the persisted code arrives; the MaterialApp
/// wires it straight into `locale`, which also drives RTL for `'ar'`.
///
/// The canonical list of supported locales lives on the generated
/// [AppLocalizations.supportedLocales] (used by MaterialApp and the Profile
/// switch) — the cubit deliberately does not duplicate it.
class LocaleCubit extends PersistedPrefCubit<Locale> {
  LocaleCubit(SettingsRepository settings) : super(const Locale('en'), settings);

  @override
  Locale? storedValue(UiPrefs prefs) =>
      prefs.localeCode == 'ar' ? const Locale('ar') : null;

  Future<void> setLocaleCode(String code) => applyChoice(
        Locale(code),
        () => settings.updateUiPrefs(localeCode: code),
      );
}

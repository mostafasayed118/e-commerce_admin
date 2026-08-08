import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/entities/ui_prefs.dart';
import '../core/error/result.dart';
import '../domain/repositories/settings_repository.dart';

/// Shared scaffolding for the persisted UI-pref cubits ([ThemeCubit],
/// [LocaleCubit]).
///
/// Both hold a single-row [UiPrefs] setting and repeat the same machinery:
/// start on a safe default, read the stored code on startup, apply it unless
/// the user already chose while the DB read was in flight (the `_userSet`
/// guard), and persist user choices best-effort. This base owns that
/// machinery; subclasses supply the initial state ([super.initial]), map the
/// stored code to a value ([storedValue], returning null for absent/unknown
/// codes so the cubit keeps its default), and expose their typed setters
/// delegating to [applyChoice].
abstract class PersistedPrefCubit<T> extends Cubit<T> {
  PersistedPrefCubit(super.initial, this.settings) {
    _restore();
  }

  /// The settings store; subclasses persist user choices through it.
  @protected
  final SettingsRepository settings;

  /// True once the user has made a choice. The async restore must never
  /// clobber a user switch that landed while the DB read was in flight.
  bool _userSet = false;

  /// The stored code's value, or null when the code is absent or unknown
  /// (the cubit keeps its initial default — e.g. only 'ar' is a supported
  /// non-default locale, and only 'light'/'dark' are valid theme modes).
  @protected
  T? storedValue(UiPrefs prefs);

  /// Applies [value] as a user choice and persists it via [write]: marks the
  /// choice so the in-flight restore can't clobber it, emits it, then
  /// best-effort writes — the choice already applied in memory; a failed
  /// write just means it won't survive the next restart.
  @protected
  Future<void> applyChoice(T value, Future<void> Function() write) async {
    _userSet = true;
    emit(value);
    await write();
  }

  /// Reads the persisted prefs and applies the stored choice, unless the
  /// user already chose while the read was in flight. Defaults to the
  /// initial state on failure — never crash startup over a pref.
  Future<void> _restore() async {
    final result = await settings.getUiPrefs();
    if (isClosed || _userSet) return;
    result.fold(
      onSuccess: (prefs) {
        final value = storedValue(prefs);
        if (value != null) emit(value);
      },
      onFailure: (_) {},
    );
  }
}

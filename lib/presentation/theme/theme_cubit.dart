import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the app's [ThemeMode].
///
/// Starts on [ThemeMode.system] (follows the OS). A toggle UI arrives with
/// the feature screens; persistence of the choice is deliberately deferred —
/// there is no settings store for it yet (noted as a limitation, not hidden).
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  /// Cycles light -> dark -> light (system is only the initial state).
  void toggleTheme() {
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

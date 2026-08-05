import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/ui_prefs.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/presentation/theme/theme_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  test('starts on system before the persisted choice loads', () {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs()));
    final cubit = ThemeCubit(repository);

    expect(cubit.state, ThemeMode.system);

    cubit.close();
  });

  test('applies the persisted dark choice once loaded', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs(themeModeCode: 'dark')));
    final cubit = ThemeCubit(repository);

    await pumpEventQueue();

    expect(cubit.state, ThemeMode.dark);

    cubit.close();
  });

  test('ignores an unknown persisted code (stays system)', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs(themeModeCode: 'sepia')));
    final cubit = ThemeCubit(repository);

    await pumpEventQueue();

    expect(cubit.state, ThemeMode.system);

    cubit.close();
  });

  test('a failed restore keeps the system default', () async {
    when(() => repository.getUiPrefs()).thenAnswer(
      (_) async => const Failure<UiPrefs>(DatabaseError(message: 'boom')),
    );
    final cubit = ThemeCubit(repository);

    await pumpEventQueue();

    expect(cubit.state, ThemeMode.system);

    cubit.close();
  });

  test('a user toggle is never clobbered by a late restore', () async {
    final completer = Completer<Result<UiPrefs>>();
    when(() => repository.getUiPrefs()).thenAnswer((_) => completer.future);
    when(
      () => repository.updateUiPrefs(
        themeModeCode: any(named: 'themeModeCode'),
      ),
    ).thenAnswer((_) async => const Success<void>(null));
    final cubit = ThemeCubit(repository);

    // User toggles before the async restore lands…
    await cubit.setThemeMode(ThemeMode.dark);
    expect(cubit.state, ThemeMode.dark);

    // …then the stale DB value arrives late — it must not overwrite the
    // choice (the restore race the _userSet guard exists for).
    completer.complete(const Success(UiPrefs(themeModeCode: 'light')));
    await pumpEventQueue();
    expect(cubit.state, ThemeMode.dark);

    cubit.close();
  });

  test('setThemeMode emits and persists the choice', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs()));
    when(
      () => repository.updateUiPrefs(
        themeModeCode: any(named: 'themeModeCode'),
      ),
    ).thenAnswer((_) async => const Success<void>(null));
    final cubit = ThemeCubit(repository);

    await cubit.setThemeMode(ThemeMode.dark);

    expect(cubit.state, ThemeMode.dark);
    verify(() => repository.updateUiPrefs(themeModeCode: 'dark')).called(1);

    cubit.close();
  });
}

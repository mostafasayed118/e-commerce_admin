import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/ui_prefs.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/presentation/persisted_pref_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

/// A minimal concrete cubit exercising the base's machinery: maps the stored
/// `themeModeCode` 'yes' → 'stored', anything else → null (keep the default).
/// Mirrors how ThemeCubit/LocaleCubit behave, without tying the test to
/// either concrete one.
class _FakePrefCubit extends PersistedPrefCubit<String> {
  _FakePrefCubit(SettingsRepository settings) : super('default', settings);

  @override
  String? storedValue(UiPrefs prefs) =>
      prefs.themeModeCode == 'yes' ? 'stored' : null;

  /// The fake's typed setter, delegating to [applyChoice] like the real ones.
  Future<void> setValue(String value) => applyChoice(
        value,
        () => settings.updateUiPrefs(themeModeCode: value),
      );
}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  test('starts on the initial default before the persisted code loads', () {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs()));
    final cubit = _FakePrefCubit(repository);

    expect(cubit.state, 'default');

    cubit.close();
  });

  test('applies the stored value once loaded', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs(themeModeCode: 'yes')));
    final cubit = _FakePrefCubit(repository);

    await pumpEventQueue();

    expect(cubit.state, 'stored');

    cubit.close();
  });

  test('an unknown stored code keeps the default', () async {
    // 'maybe' is not a recognized code → storedValue returns null.
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs(themeModeCode: 'maybe')));
    final cubit = _FakePrefCubit(repository);

    await pumpEventQueue();

    expect(cubit.state, 'default');

    cubit.close();
  });

  test('a failed restore keeps the default', () async {
    when(() => repository.getUiPrefs()).thenAnswer(
      (_) async => const Failure<UiPrefs>(DatabaseError(message: 'boom')),
    );
    final cubit = _FakePrefCubit(repository);

    await pumpEventQueue();

    expect(cubit.state, 'default');

    cubit.close();
  });

  test('a user choice is never clobbered by a late restore', () async {
    final restore = Completer<Result<UiPrefs>>();
    final write = Completer<Result<void>>();
    when(() => repository.getUiPrefs()).thenAnswer((_) => restore.future);
    when(
      () => repository.updateUiPrefs(themeModeCode: any(named: 'themeModeCode')),
    ).thenAnswer((_) => write.future);
    final cubit = _FakePrefCubit(repository);

    // Start a user choice; its persist write is still in flight.
    final choice = cubit.setValue('user-choice');
    expect(cubit.state, 'user-choice');

    // A stale stored value lands mid-write — the guard (_userSet set before
    // the await) must fire before the restore can clobber the choice.
    restore.complete(const Success(UiPrefs(themeModeCode: 'yes')));
    await pumpEventQueue();
    expect(cubit.state, 'user-choice');

    // Finish the write; still no clobber.
    write.complete(const Success<void>(null));
    await choice;
    expect(cubit.state, 'user-choice');

    cubit.close();
  });

  test('setValue emits and persists through applyChoice', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs()));
    when(
      () => repository.updateUiPrefs(themeModeCode: any(named: 'themeModeCode')),
    ).thenAnswer((_) async => const Success<void>(null));
    final cubit = _FakePrefCubit(repository);

    await cubit.setValue('user-choice');

    expect(cubit.state, 'user-choice');
    verify(
      () => repository.updateUiPrefs(themeModeCode: 'user-choice'),
    ).called(1);

    cubit.close();
  });

  test('a failed persist keeps the in-memory choice', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs()));
    when(
      () => repository.updateUiPrefs(themeModeCode: any(named: 'themeModeCode')),
    ).thenAnswer((_) async => const Failure<void>(DatabaseError(message: 'no')));

    final cubit = _FakePrefCubit(repository);

    // Best-effort write: the choice already applied; the failed save must
    // not throw or revert it.
    await cubit.setValue('user-choice');
    expect(cubit.state, 'user-choice');

    cubit.close();
  });
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/ui_prefs.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/presentation/locale/locale_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  test('starts on English before the persisted code loads', () {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs()));
    final cubit = LocaleCubit(repository);

    expect(cubit.state, const Locale('en'));

    cubit.close();
  });

  test('restores Arabic when that code was persisted', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs(localeCode: 'ar')));
    final cubit = LocaleCubit(repository);

    await pumpEventQueue();

    expect(cubit.state, const Locale('ar'));

    cubit.close();
  });

  test('a user switch is never clobbered by a late restore', () async {
    final completer = Completer<Result<UiPrefs>>();
    when(() => repository.getUiPrefs()).thenAnswer((_) => completer.future);
    when(
      () => repository.updateUiPrefs(localeCode: any(named: 'localeCode')),
    ).thenAnswer((_) async => const Success<void>(null));
    final cubit = LocaleCubit(repository);

    await cubit.setLocaleCode('ar');
    expect(cubit.state, const Locale('ar'));

    // The stale DB value (en) arrives late — must not overwrite the choice.
    completer.complete(const Success(UiPrefs(localeCode: 'en')));
    await pumpEventQueue();
    expect(cubit.state, const Locale('ar'));

    cubit.close();
  });

  test('setLocaleCode emits and persists the code', () async {
    when(() => repository.getUiPrefs())
        .thenAnswer((_) async => const Success(UiPrefs()));
    when(
      () => repository.updateUiPrefs(localeCode: any(named: 'localeCode')),
    ).thenAnswer((_) async => const Success<void>(null));
    final cubit = LocaleCubit(repository);

    await cubit.setLocaleCode('ar');

    expect(cubit.state, const Locale('ar'));
    verify(() => repository.updateUiPrefs(localeCode: 'ar')).called(1);

    cubit.close();
  });
}

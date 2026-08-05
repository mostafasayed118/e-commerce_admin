import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/domain/usecases/profile/save_profile.dart';
import 'package:shop_admin/presentation/features/profile/profile_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockSaveProfile extends Mock implements SaveProfile {}

void main() {
  late MockSettingsRepository repository;
  late MockSaveProfile saveProfile;
  late StreamController<ShippingInfo?> profileCtrl;

  setUpAll(() {
    // `any()` on a ShippingInfo parameter needs a registered fallback.
    registerFallbackValue(const ShippingInfo());
  });

  setUp(() {
    repository = MockSettingsRepository();
    saveProfile = MockSaveProfile();
    // Synchronous broadcast controller: emissions land immediately, and only
    // after the cubit has subscribed (broadcast drops early emissions).
    profileCtrl = StreamController<ShippingInfo?>.broadcast(sync: true);
    when(() => repository.watchProfile()).thenAnswer((_) => profileCtrl.stream);
  });

  tearDown(() async {
    await profileCtrl.close();
  });

  ProfileCubit build() => ProfileCubit(repository, saveProfile);

  test('starts loading and emits loaded once the stream has emitted', () {
    final cubit = build();
    expect(cubit.state, isA<ProfileLoading>());

    profileCtrl.add(const ShippingInfo(name: 'A'));
    final loaded = cubit.state as ProfileLoaded;
    expect(loaded.profile, const ShippingInfo(name: 'A'));
    expect(loaded.saving, isFalse);
    expect(loaded.saveError, isNull);
    expect(loaded.justSaved, isFalse);

    cubit.close();
  });

  test('a null emission is an empty profile (the screen shows a blank form)',
      () {
    final cubit = build();
    profileCtrl.add(null);

    final loaded = cubit.state as ProfileLoaded;
    expect(loaded.profile, const ShippingInfo());
    expect(loaded.profile.isEmpty, isTrue);

    cubit.close();
  });

  test('save toggles saving, then reports success', () async {
    final cubit = build();
    profileCtrl.add(const ShippingInfo(name: 'A'));

    final completer = Completer<Result<void>>();
    when(() => saveProfile(const ShippingInfo(name: 'B')))
        .thenAnswer((_) => completer.future);

    final saveFuture = cubit.save(const ShippingInfo(name: 'B'));
    expect((cubit.state as ProfileLoaded).saving, isTrue);

    completer.complete(const Success<void>(null));
    await saveFuture;

    final loaded = cubit.state as ProfileLoaded;
    expect(loaded.saving, isFalse);
    expect(loaded.justSaved, isTrue);
    expect(loaded.saveError, isNull);

    cubit.close();
  });

  test('a failed save reports the error and never claims success', () async {
    final cubit = build();
    profileCtrl.add(const ShippingInfo(name: 'A'));

    when(() => saveProfile(any())).thenAnswer(
      (_) async => const Failure<void>(
        DatabaseError(message: 'Could not save profile'),
      ),
    );

    await cubit.save(const ShippingInfo(name: 'B'));

    final loaded = cubit.state as ProfileLoaded;
    expect(loaded.saving, isFalse);
    expect(loaded.saveError, 'Could not save profile');
    expect(loaded.justSaved, isFalse);

    cubit.close();
  });

  test('a *throwing* save reports the error and never wedges the button',
      () async {
    final cubit = build();
    profileCtrl.add(const ShippingInfo(name: 'A'));

    // Simulate the one path the repository's Result boundary doesn't
    // convert: an escaped Error. The button must not stay disabled forever.
    when(() => saveProfile(any())).thenThrow(Exception('boom'));
    await cubit.save(const ShippingInfo(name: 'B'));

    final loaded = cubit.state as ProfileLoaded;
    expect(loaded.saving, isFalse);
    expect(loaded.saveError, 'Could not save profile');
    expect(loaded.justSaved, isFalse);

    // And a subsequent save still works.
    when(() => saveProfile(any()))
        .thenAnswer((_) async => const Success<void>(null));
    await cubit.save(const ShippingInfo(name: 'B'));
    expect((cubit.state as ProfileLoaded).justSaved, isTrue);

    cubit.close();
  });

  test('a save in flight ignores a second save (no double-tap)', () async {
    final cubit = build();
    profileCtrl.add(const ShippingInfo(name: 'A'));

    final completer = Completer<Result<void>>();
    when(() => saveProfile(any())).thenAnswer((_) => completer.future);

    final first = cubit.save(const ShippingInfo(name: 'B'));
    final second = cubit.save(const ShippingInfo(name: 'C'));
    expect((cubit.state as ProfileLoaded).saving, isTrue);

    completer.complete(const Success<void>(null));
    await first;
    await second;

    // Only the first save reached the use case.
    verify(() => saveProfile(any())).called(1);

    cubit.close();
  });

  test('a stream error becomes ProfileError and is sticky', () {
    final cubit = build();
    profileCtrl.add(const ShippingInfo(name: 'A'));
    expect(cubit.state, isA<ProfileLoaded>());

    profileCtrl.addError(StateError('boom'));
    expect(cubit.state, isA<ProfileError>());

    // A later emission must not resurrect the loaded state.
    profileCtrl.add(const ShippingInfo(name: 'A'));
    expect(cubit.state, isA<ProfileError>());

    cubit.close();
  });

  test('close cancels the stream subscription', () async {
    final cubit = build();
    cubit.close();
    expect(profileCtrl.hasListener, isFalse);
  });
}

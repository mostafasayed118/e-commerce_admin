import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/domain/usecases/profile/save_profile.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

/// Pins SaveProfile's contract — the domain gate shared with the profile
/// screen: normalize (trim) → validate → persist through the same
/// [normalizeAndValidateShipping] rule as order placement, so the two writers
/// of the single-row profile table can never disagree.
void main() {
  late MockSettingsRepository settings;
  late SaveProfile saveProfile;

  setUpAll(() {
    // mocktail: any() on the non-nullable ShippingInfo parameter needs a
    // registered fallback value.
    registerFallbackValue(const ShippingInfo());
  });

  setUp(() {
    settings = MockSettingsRepository();
    saveProfile = SaveProfile(settings);
  });

  void mockUpdate(Result<void> result) {
    when(() => settings.updateProfile(any())).thenAnswer((_) async => result);
  }

  test('a valid profile is normalized (trimmed) and persisted', () async {
    mockUpdate(const Success<void>(null));

    final result = await saveProfile(
      const ShippingInfo(name: '  Ada  ', phone: ' 0100 ', address: ' Cairo '),
    );

    expect(result, isA<Success<void>>());
    verify(() => settings.updateProfile(
      const ShippingInfo(name: 'Ada', phone: '0100', address: 'Cairo'),
    )).called(1);
  });

  test('an already-clean profile is forwarded unchanged', () async {
    mockUpdate(const Success<void>(null));
    const profile = ShippingInfo(name: 'Ada', phone: '0100', address: 'Cairo');

    await saveProfile(profile);

    verify(() => settings.updateProfile(profile)).called(1);
  });

  test('a blank field is rejected before touching the repository', () async {
    const profile = ShippingInfo(name: '', phone: '0100', address: 'Cairo');

    final result = await saveProfile(profile);

    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error, isA<ValidationError>());
    verifyNever(() => settings.updateProfile(any()));
  });

  test('a repository failure propagates unchanged', () async {
    const dbError = DatabaseError(message: 'Could not save profile');
    mockUpdate(const Failure<void>(dbError));

    final result = await saveProfile(
      const ShippingInfo(name: 'Ada', phone: '0100', address: 'Cairo'),
    );

    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error, same(dbError));
  });
}

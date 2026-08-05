import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/core/utils/security.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/settings_dao.dart';
import 'package:shop_admin/data/repositories/settings_repository_impl.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepositoryImpl(SettingsDao(db));
  });

  tearDown(() => db.close());

  group('profile', () {
    test('is null before first save', () async {
      expect((await repo.getProfile()).getOrThrow(), isNull);
      expect(await repo.watchProfile().first, isNull);
    });

    test('updateProfile persists and stamps updatedAt', () async {
      const profile = ShippingInfo(
        name: 'Amira Hassan',
        phone: '0100 000 0001',
        address: '14 Nile St, Cairo',
      );

      expect(await repo.updateProfile(profile), isA<Success<void>>());

      final saved = (await repo.getProfile()).getOrThrow();
      expect(saved, profile);
      final row = await (db.select(db.profile)).getSingle();
      expect(row.updatedAt, isNotNull);
    });

    test('updating again replaces the single row and bumps updatedAt',
        () async {
      await repo.updateProfile(
        const ShippingInfo(name: 'A', phone: '', address: ''),
      );
      final firstStamp =
          (await (db.select(db.profile)).getSingle()).updatedAt;

      await repo.updateProfile(
        const ShippingInfo(name: 'B', phone: '0100', address: 'St 1'),
      );

      expect(await (db.select(db.profile)).get(), hasLength(1));
      expect((await repo.getProfile()).getOrThrow()!.name, 'B');
      final secondStamp =
          (await (db.select(db.profile)).getSingle()).updatedAt;
      expect(secondStamp, greaterThan(firstStamp!));
    });

    test('watchProfile emits the profile after a save', () async {
      final done = expectLater(
        repo.watchProfile(),
        emitsInOrder([isNull, const ShippingInfo(name: 'A')]),
      );

      await pumpEventQueue();
      await repo.updateProfile(const ShippingInfo(name: 'A'));

      await done;
    });
  });

  group('admin PIN gate', () {
    test('isPinSet is false before any PIN exists', () async {
      expect((await repo.isPinSet()).getOrThrow(), isFalse);
    });

    test('setPin then verifyPin accepts the correct PIN', () async {
      expect(await repo.setPin('1234'), isA<Success<void>>());
      expect((await repo.isPinSet()).getOrThrow(), isTrue);

      expect(await repo.verifyPin('1234'), isA<Success<void>>());
    });

    test('verifyPin rejects a wrong PIN with PinError', () async {
      await repo.setPin('1234');

      final result = await repo.verifyPin('9999');
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<PinError>());
    });

    test('verifyPin yields PinError when no PIN is set', () async {
      final result = await repo.verifyPin('1234');
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<PinError>());
    });

    test('setPin rejects invalid formats with ValidationError', () async {
      for (final bad in ['', '123', '1234567', '12a4']) {
        final result = await repo.setPin(bad);
        expect(result, isA<Failure<void>>(),
            reason: 'PIN "$bad" must be rejected');
        expect((result as Failure<void>).error, isA<ValidationError>());
      }
      expect((await repo.isPinSet()).getOrThrow(), isFalse,
          reason: 'failed setPin must not leave a PIN behind');
    });

    test('persists only a salted hash, never the raw PIN', () async {
      await repo.setPin('1234');

      final row = await (db.select(db.adminSettings)).getSingle();
      expect(row.pinHash, isNot('1234'));
      expect(row.pinHash, hashPin('1234', row.pinSalt),
          reason: 'the stored hash must verify against the stored salt');
      expect(row.pinSalt, isNotEmpty);
    });

    test('re-setting the PIN replaces the single row', () async {
      await repo.setPin('1234');
      await repo.setPin('5678');

      expect(await (db.select(db.adminSettings)).get(), hasLength(1));
      expect(await repo.verifyPin('1234'), isA<Failure<void>>());
      expect(await repo.verifyPin('5678'), isA<Success<void>>());
    });
  });
}

import 'package:drift/drift.dart';

import '../../core/entities/shipping_info.dart';
import '../../core/entities/ui_prefs.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../core/utils/security.dart';
import '../../domain/repositories/settings_repository.dart';
import '../database/app_database.dart';
import '../database/daos/settings_dao.dart';

/// drift-backed [SettingsRepository].
///
/// The error boundary (Section D.4): every operation wraps storage failures
/// in [Result] here. The PIN format rule lives here too — the DB stores only
/// the opaque hash, so it cannot CHECK the PIN shape.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dao);

  final SettingsDao _dao;

  @override
  Stream<ShippingInfo?> watchProfile() => _dao.watchProfile().map(
        (row) => row == null ? null : _toShippingInfo(row),
      );

  @override
  Future<Result<ShippingInfo?>> getProfile() async {
    try {
      final row = await _dao.getProfile();
      return Success(row == null ? null : _toShippingInfo(row));
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not load profile', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> updateProfile(ShippingInfo profile) async {
    try {
      await _dao.upsertProfile(ProfileCompanion.insert(
        // id is the (non-autoIncrement) primary key, hence Value().
        id: const Value(1),
        name: Value(profile.name),
        phone: Value(profile.phone),
        address: Value(profile.address),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not save profile', cause: error),
      );
    }
  }

  @override
  Stream<UiPrefs> watchUiPrefs() =>
      _dao.watchUiPrefs().map(_toUiPrefs);

  @override
  Future<Result<UiPrefs>> getUiPrefs() async {
    try {
      return Success(_toUiPrefs(await _dao.getUiPrefs()));
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not load preferences', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> updateUiPrefs({
    String? themeModeCode,
    String? localeCode,
  }) async {
    try {
      // Absent columns (Value.absent) keep their stored value on conflict,
      // so a theme-only write never wipes the stored locale and vice versa.
      await _dao.upsertUiPrefs(UiPrefsCompanion.insert(
        id: const Value(1),
        themeMode: themeModeCode == null
            ? const Value.absent()
            : Value(themeModeCode),
        localeCode: localeCode == null
            ? const Value.absent()
            : Value(localeCode),
      ));
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not save preferences', cause: error),
      );
    }
  }

  @override
  Future<Result<bool>> isPinSet() async {
    try {
      return Success((await _dao.getAdminSettings()) != null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not read PIN settings', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> setPin(String pin) async {
    if (!isValidPin(pin)) {
      return const Failure(
        ValidationError(message: 'PIN must be 4-6 digits'),
      );
    }
    try {
      final salt = generateSalt();
      await _dao.upsertAdminSettings(AdminSettingsCompanion.insert(
        id: const Value(1),
        pinHash: hashPin(pin, salt),
        pinSalt: salt,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not save PIN', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> verifyPin(String pin) async {
    try {
      final row = await _dao.getAdminSettings();
      if (row == null) {
        return const Failure(PinError(message: 'PIN has not been set'));
      }
      // Compare the hash of the presented PIN against the stored hash. The
      // equality check is not constant-time; acceptable for a mock local
      // gate where the attacker already has the DB on the same device.
      if (hashPin(pin, row.pinSalt) != row.pinHash) {
        return const Failure(PinError(message: 'Incorrect PIN'));
      }
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not verify PIN', cause: error),
      );
    }
  }

  ShippingInfo _toShippingInfo(ProfileRow row) => ShippingInfo(
        name: row.name ?? '',
        phone: row.phone ?? '',
        address: row.address ?? '',
      );

  UiPrefs _toUiPrefs(UiPrefsRow? row) => UiPrefs(
        themeModeCode: row?.themeMode,
        localeCode: row?.localeCode,
      );
}

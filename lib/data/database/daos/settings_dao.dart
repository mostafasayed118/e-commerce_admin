import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// Data access for the two single-row settings tables: the customer [Profile]
/// (checkout pre-fill) and the admin [AdminSettings] (salted PIN hash).
///
/// Both rows are keyed by the fixed id `1`, so every write is an upsert via
/// `insertOnConflictUpdate` — no read-modify-write needed (unlike the cart,
/// there is nothing to preserve on update).
@DriftAccessor(tables: [Profile, AdminSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  /// Reactive profile; emits `null` until first saved.
  Stream<ProfileRow?> watchProfile() {
    return (select(profile)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<ProfileRow?> getProfile() {
    return (select(profile)..where((t) => t.id.equals(1))).getSingleOrNull();
  }

  /// Inserts or replaces the single profile row.
  Future<void> upsertProfile(ProfileCompanion companion) =>
      into(profile).insertOnConflictUpdate(companion);

  Future<AdminSettingsRow?> getAdminSettings() {
    return (select(adminSettings)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  /// Inserts or replaces the single admin-settings row (set/change PIN).
  Future<void> upsertAdminSettings(AdminSettingsCompanion companion) =>
      into(adminSettings).insertOnConflictUpdate(companion);
}

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// Data access for the single-row settings tables: the customer [Profile]
/// (checkout pre-fill), the admin [AdminSettings] (salted PIN hash), and
/// [UiPrefs] (persisted theme/locale).
///
/// All rows are keyed by the fixed id `1`, so every write is an upsert via
/// `insertOnConflictUpdate` — no read-modify-write needed (unlike the cart,
/// there is nothing to preserve on update). For [UiPrefs] specifically,
/// absent companion columns keep their stored value on conflict, which is
/// exactly the theme/locale merge we want.
@DriftAccessor(tables: [Profile, AdminSettings, UiPrefs])
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

  /// Reactive UI preferences; emits `null` until first saved.
  Stream<UiPrefsRow?> watchUiPrefs() {
    return (select(uiPrefs)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<UiPrefsRow?> getUiPrefs() {
    return (select(uiPrefs)..where((t) => t.id.equals(1))).getSingleOrNull();
  }

  /// Inserts or replaces the single prefs row. Absent companion columns
  /// (via [Value.absent]) keep their stored value on conflict, so theme and
  /// locale merge in one write with no read-modify-write.
  Future<void> upsertUiPrefs(UiPrefsCompanion companion) =>
      into(uiPrefs).insertOnConflictUpdate(companion);

  Future<AdminSettingsRow?> getAdminSettings() {
    return (select(adminSettings)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  /// Inserts or replaces the single admin-settings row (set/change PIN).
  Future<void> upsertAdminSettings(AdminSettingsCompanion companion) =>
      into(adminSettings).insertOnConflictUpdate(companion);
}

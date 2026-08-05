// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_dao.dart';

// ignore_for_file: type=lint
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProfileTable get profile => attachedDatabase.profile;
  $AdminSettingsTable get adminSettings => attachedDatabase.adminSettings;
  $UiPrefsTable get uiPrefs => attachedDatabase.uiPrefs;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$ProfileTableTableManager get profile =>
      $$ProfileTableTableManager(_db.attachedDatabase, _db.profile);
  $$AdminSettingsTableTableManager get adminSettings =>
      $$AdminSettingsTableTableManager(_db.attachedDatabase, _db.adminSettings);
  $$UiPrefsTableTableManager get uiPrefs =>
      $$UiPrefsTableTableManager(_db.attachedDatabase, _db.uiPrefs);
}

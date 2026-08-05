import 'package:drift/native.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';

/// Runs the app's composition root, then swaps the real (file-backed)
/// [AppDatabase] registration for an in-memory one, so presentation tests
/// never touch the device database.
///
/// The caller owns the returned database: close it and call `getIt.reset()`
/// in tearDown.
AppDatabase setupTestDi() {
  setupDependencies();
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  getIt.allowReassignment = true;
  getIt.registerSingleton<AppDatabase>(db);
  getIt.allowReassignment = false;
  return db;
}

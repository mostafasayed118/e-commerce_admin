import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/entities/order_status.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The single source of truth for persistence: SQLite via drift.
///
/// The app opens the database with [driftDatabase] (drift_flutter handles
/// native sqlite3 setup on Android and Windows). Tests inject any
/// [QueryExecutor] — typically `NativeDatabase.memory()` — via
/// [AppDatabase.forTesting].
@DriftDatabase(tables: [
  Categories,
  Products,
  CartItems,
  Orders,
  OrderItems,
  OrderStatusHistory,
  Profile,
  AdminSettings,
  UiPrefs,
  AppMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'shop_admin'));

  /// Test seam: allows DAO/repository tests to run on an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // The first real migration: v2 adds the single-row UiPrefs table
          // (persisted theme/locale). Existing v1 installs (e.g. the release
          // APK on a device) get the table added without touching their data;
          // new installs create everything in onCreate. Seed re-runs stay
          // decoupled via AppMeta.seedVersion, not migrations.
          if (from < 2) {
            await m.createTable(uiPrefs);
          }
        },
        beforeOpen: (details) async {
          // Drift does NOT enable foreign-key enforcement by default; without
          // this line, ON DELETE CASCADE / SET NULL / RESTRICT are dead
          // letters and the CHECK constraints still apply.
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}

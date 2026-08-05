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
  AppMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'shop_admin'));

  /// Test seam: allows DAO/repository tests to run on an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Schema v1 ships with no upgrades yet. Future versions chain
          // migration steps here (PLAN: migrations versioned from v1; seed
          // re-runs are decoupled via AppMeta.seedVersion, not migrations).
        },
        beforeOpen: (details) async {
          // Drift does NOT enable foreign-key enforcement by default; without
          // this line, ON DELETE CASCADE / SET NULL / RESTRICT are dead
          // letters and the CHECK constraints still apply.
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}

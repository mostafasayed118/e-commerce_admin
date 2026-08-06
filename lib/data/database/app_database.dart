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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v2 adds the single-row UiPrefs table (persisted theme/locale).
          if (from < 2) {
            await m.createTable(uiPrefs);
          }
          // v3 adds optional Arabic content columns (localized seed data and
          // bilingual order receipts). All nullable, so existing rows are
          // untouched and simply fall back to English until reseeded.
          if (from < 3) {
            await m.addColumn(products, products.nameAr);
            await m.addColumn(products, products.descriptionAr);
            await m.addColumn(categories, categories.nameAr);
            await m.addColumn(orderItems, orderItems.productNameAr);
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

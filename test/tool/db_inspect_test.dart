import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Verifies the database a real device produced on a FRESH INSTALL of the
/// app: schema at v3 (Arabic columns present) and seed at v2 (all demo rows
/// carry Arabic content). The file is pulled from the device
/// (`adb exec-out run-as ... cat app_flutter/shop_admin.sqlite`) and pointed
/// to via the DB_PATH env var.
///
/// Run with: `DB_PATH=/tmp/dbcheck/app.sqlite flutter test test/tool/db_inspect_test.dart`
void main() {
  test('pulled device DB is schema v3, seed v2, with Arabic content', () {
    final path = Platform.environment['DB_PATH'];
    if (path == null) {
      markTestSkipped('set DB_PATH to the pulled shop_admin.sqlite file');
      return;
    }

    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    try {
      final userVersion =
          db.select('PRAGMA user_version').first['user_version'] as int;
      expect(userVersion, 3,
          reason: 'fresh install must create the schema at v3');

      final seedVersion = db
          .select('SELECT seed_version FROM app_meta WHERE id = 1')
          .first['seed_version'] as int;
      expect(seedVersion, 2,
          reason: 'fresh install must run the v2 bilingual seed');

      final productAr = db.select(
          'SELECT COUNT(*) AS c FROM products WHERE name_ar IS NOT NULL')
          .first['c'] as int;
      // The seed has 13 products (4 clothing + 3 electronics + 2 home &
      // kitchen + 2 books + 2 sports).
      expect(productAr, 13,
          reason: 'every seeded product must carry an Arabic name');

      final categoryAr = db.select(
          'SELECT COUNT(*) AS c FROM categories WHERE name_ar IS NOT NULL')
          .first['c'] as int;
      expect(categoryAr, 5,
          reason: 'all 5 seeded categories must carry Arabic labels');

      final orderItemsAr = db.select(
          'SELECT COUNT(*) AS c FROM order_items WHERE product_name_ar IS NOT NULL')
          .first['c'] as int;
      expect(orderItemsAr, 10,
          reason: 'all 10 seeded order-line snapshots must carry Arabic');
    } finally {
      db.close();
    }
  });
}

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';

/// A database pinned to schema v1, so reopening the real (current-version)
/// database on the same file exercises the on-device upgrade path (a release
/// build on a device ships with an older schema version).
class _V1Database extends AppDatabase {
  // The implicit super constructor (AppDatabase()) takes no parameters, so
  // the executor must be forwarded explicitly — a super parameter would
  // resolve to the unnamed constructor and fail to compile.
  // ignore: use_super_parameters
  _V1Database.forTesting(QueryExecutor executor) : super.forTesting(executor);

  @override
  int get schemaVersion => 1;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('migrates an old install: adds UiPrefs + Arabic columns, keeps data',
      () async {
    final file = File(
      '${Directory.systemTemp.path}/shop_admin_migration_'
      '${DateTime.now().millisecondsSinceEpoch}.db',
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    // 1. Write data the way an old install would (a profile row exists).
    final v1 = _V1Database.forTesting(NativeDatabase(file));
    await v1.into(v1.profile).insert(ProfileCompanion.insert(
          id: const Value(1),
          name: const Value('Legacy User'),
          phone: const Value('555-0100'),
          address: const Value('1 Old St'),
          updatedAt: Value(1),
        ));

    // The simulated old install is created from the CURRENT table
    // definitions (tables.dart is shared), so drop the v3 Arabic columns to
    // match the real v2-era shape — otherwise the upgrade's ALTER TABLE
    // would collide with columns that already exist.
    for (final statement in [
      'ALTER TABLE products DROP COLUMN name_ar;',
      'ALTER TABLE products DROP COLUMN description_ar;',
      'ALTER TABLE categories DROP COLUMN name_ar;',
      'ALTER TABLE order_items DROP COLUMN product_name_ar;',
    ]) {
      await v1.customStatement(statement);
    }
    await v1.close();

    // 2. Reopen with the real (current) schema: onUpgrade adds the UiPrefs
    // table and the Arabic columns without touching existing rows.
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    final profile = await upgraded.select(upgraded.profile).getSingle();
    expect(profile.name, 'Legacy User'); // existing data survived

    // The new table works, and the single-row id=1 check is enforced.
    await upgraded.into(upgraded.uiPrefs).insert(UiPrefsCompanion.insert(
          id: const Value(1),
          themeMode: const Value('dark'),
        ));
    final prefs = await upgraded.select(upgraded.uiPrefs).getSingle();
    expect(prefs.themeMode, 'dark');

    // The added Arabic columns accept and return data.
    final categoryId = await upgraded.into(upgraded.categories).insert(
          CategoriesCompanion.insert(
            name: 'Clothing',
            nameAr: const Value('ملابس'),
            createdAt: 1,
          ),
        );
    await upgraded.into(upgraded.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T-Shirt',
          nameAr: const Value('تيشيرت'),
          priceCents: 2000,
          discountPercent: 0,
          stock: 5,
          createdAt: 1,
          updatedAt: 1,
        ));
    final product = await upgraded.select(upgraded.products).getSingle();
    expect(product.nameAr, 'تيشيرت');

    await upgraded.close();
  });

  test('a GENUINE v1 database (no UiPrefs, no Arabic columns) migrates to v3 '
      'and reseeds to v2', () async {
    final file = File(
      '${Directory.systemTemp.path}/shop_admin_true_v1_'
      '${DateTime.now().millisecondsSinceEpoch}.db',
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    // 1. Build the exact schema a shipped v1 release created: raw SQL with
    //    NO ui_prefs table and NO Arabic columns, plus the v1-era app_meta
    //    (seedVersion 1) and a legacy profile row.
    final v1 = sqlite3.open(file.path);
    v1.execute('''
CREATE TABLE categories (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL
);
CREATE TABLE products (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL REFERENCES categories (id),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
  discount_percent INTEGER NOT NULL CHECK (discount_percent >= 0 AND discount_percent <= 100),
  stock INTEGER NOT NULL CHECK (stock >= 0),
  image_path TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE cart_items (
  product_id INTEGER NOT NULL PRIMARY KEY REFERENCES products (id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  added_at INTEGER NOT NULL
);
CREATE TABLE orders (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  order_number TEXT NOT NULL UNIQUE,
  status INTEGER NOT NULL,
  subtotal_cents INTEGER NOT NULL CHECK (subtotal_cents >= 0),
  discount_cents INTEGER NOT NULL CHECK (discount_cents >= 0),
  total_cents INTEGER NOT NULL CHECK (total_cents >= 0),
  shipping_name TEXT NOT NULL,
  shipping_phone TEXT NOT NULL,
  shipping_address TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE order_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products (id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
  discount_percent INTEGER NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
  quantity INTEGER NOT NULL CHECK (quantity > 0)
);
CREATE TABLE order_status_history (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  status INTEGER NOT NULL,
  changed_at INTEGER NOT NULL
);
CREATE TABLE profile (
  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
  name TEXT,
  phone TEXT,
  address TEXT,
  updated_at INTEGER
);
CREATE TABLE admin_settings (
  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
  pin_hash TEXT NOT NULL,
  pin_salt TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE TABLE app_meta (
  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
  seed_version INTEGER NOT NULL DEFAULT 0
);
''');
    v1.execute('PRAGMA user_version = 1;');
    v1.execute(
        "INSERT INTO profile (id, name, phone, address, updated_at) "
        "VALUES (1, 'Legacy User', '555-0100', '1 Old St', 1);");
    v1.execute('INSERT INTO app_meta (id, seed_version) VALUES (1, 1);');
    v1.close();

    // 2. Reopen with the real (v3) schema: onUpgrade must CREATE the missing
    //    ui_prefs table and ADD the Arabic columns — the branches the
    //    previous simulation (current schema minus columns) never hit.
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    final profile = await upgraded.select(upgraded.profile).getSingle();
    expect(profile.name, 'Legacy User', reason: 'user data must survive');

    // The newly-created ui_prefs table works.
    await upgraded.into(upgraded.uiPrefs).insert(UiPrefsCompanion.insert(
          id: const Value(1),
          themeMode: const Value('dark'),
        ));
    expect(
      (await upgraded.select(upgraded.uiPrefs).getSingle()).themeMode,
      'dark',
    );

    // The newly-added Arabic columns accept and return data.
    await upgraded.into(upgraded.categories).insert(
          CategoriesCompanion.insert(
            name: 'Clothing',
            nameAr: const Value('ملابس'),
            createdAt: 1,
          ),
        );
    expect(
      (await upgraded.select(upgraded.categories).getSingle()).nameAr,
      'ملابس',
    );

    // 3. A v1-era install (seedVersion 1) then reseeds to v2: clear +
    //    reinsert with Arabic, still leaving user data alone.
    await SeedData(upgraded).seedIfNeeded();
    final meta = await (upgraded.select(upgraded.appMeta)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    expect(meta.seedVersion, SeedData.version);
    final products = await upgraded.select(upgraded.products).get();
    expect(products, isNotEmpty);
    expect(products.every((p) => p.nameAr != null), isTrue,
        reason: 'the v2 reseed must carry Arabic content');
    expect(
      (await upgraded.select(upgraded.profile).getSingle()).name,
      'Legacy User',
      reason: 'reseed must not touch user data',
    );
    // The category we inserted before the reseed was wiped and re-seeded.
    expect(await upgraded.select(upgraded.categories).get(), hasLength(5));

    await upgraded.close();
  });

  test('opens with all ten tables empty', () async {
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.products).get(), isEmpty);
    expect(await db.select(db.cartItems).get(), isEmpty);
    expect(await db.select(db.orders).get(), isEmpty);
    expect(await db.select(db.orderItems).get(), isEmpty);
    expect(await db.select(db.orderStatusHistory).get(), isEmpty);
    expect(await db.select(db.profile).get(), isEmpty);
    expect(await db.select(db.adminSettings).get(), isEmpty);
    expect(await db.select(db.uiPrefs).get(), isEmpty);
    expect(await db.select(db.appMeta).get(), isEmpty);
  });

  test('single-row tables reject any row other than id 1', () async {
    await expectLater(
      db.into(db.profile).insert(ProfileCompanion.insert(id: Value(2))),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.into(db.appMeta).insert(AppMetaCompanion.insert(id: Value(2))),
      throwsA(isA<SqliteException>()),
    );
  });

  test('category and product rows round-trip', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'Clothing', createdAt: 1),
        );
    await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T-Shirt',
          priceCents: 2000,
          discountPercent: 25,
          stock: 10,
          createdAt: 1,
          updatedAt: 1,
        ));

    final product = await db.select(db.products).getSingle();
    expect(product.name, 'T-Shirt');
    expect(product.priceCents, 2000);
    expect(product.discountPercent, 25);
    expect(product.stock, 10);
    expect(product.imagePath, isNull);
    expect(product.description, '');
  });

  test('CHECK constraints reject invalid product rows', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );

    Future<void> insertProduct({
      required String name,
      required int priceCents,
      int discountPercent = 0,
      int stock = 1,
    }) {
      return db.into(db.products).insert(ProductsCompanion.insert(
            categoryId: categoryId,
            name: name,
            priceCents: priceCents,
            discountPercent: discountPercent,
            stock: stock,
            createdAt: 1,
            updatedAt: 1,
          ));
    }

    await expectLater(
      insertProduct(name: 'negative price', priceCents: -1),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertProduct(name: 'discount over 100', priceCents: 100, discountPercent: 101),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertProduct(name: 'negative stock', priceCents: 100, stock: -2),
      throwsA(isA<SqliteException>()),
    );
  });

  test('CHECK constraint rejects a zero-quantity cart row', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    final productId = await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'P',
          priceCents: 100,
          discountPercent: 0,
          stock: 1,
          createdAt: 1,
          updatedAt: 1,
        ));

    await expectLater(
      db.into(db.cartItems).insert(
        CartItemsCompanion.insert(
          productId: Value(productId),
          quantity: 0,
          addedAt: 1,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('foreign keys are enforced: unknown category is rejected', () async {
    await expectLater(
      db.into(db.products).insert(ProductsCompanion.insert(
            categoryId: 999,
            name: 'Orphan',
            priceCents: 100,
            discountPercent: 0,
            stock: 1,
            createdAt: 1,
            updatedAt: 1,
          )),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a category with products cannot be deleted (RESTRICT)', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'P',
          priceCents: 100,
          discountPercent: 0,
          stock: 1,
          createdAt: 1,
          updatedAt: 1,
        ));

    await expectLater(
      (db.delete(db.categories)..where((t) => t.id.equals(categoryId))).go(),
      throwsA(isA<SqliteException>()),
    );
  });

  test('deleting a product cascades its cart rows away', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    final productId = await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'P',
          priceCents: 100,
          discountPercent: 0,
          stock: 1,
          createdAt: 1,
          updatedAt: 1,
        ));
    await db.into(db.cartItems).insert(
      CartItemsCompanion.insert(
        productId: Value(productId),
        quantity: 2,
        addedAt: 1,
      ),
    );
    expect(await db.select(db.cartItems).get(), hasLength(1));

    await (db.delete(db.products)..where((t) => t.id.equals(productId))).go();

    expect(await db.select(db.cartItems).get(), isEmpty);
  });

  test('deleting a product sets order item productId null but keeps snapshots', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    final productId = await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T',
          priceCents: 2000,
          discountPercent: 25,
          stock: 3,
          createdAt: 1,
          updatedAt: 1,
        ));
    final orderId = await db.into(db.orders).insert(OrdersCompanion.insert(
          orderNumber: 'ORD-000001',
          status: OrderStatus.pending,
          subtotalCents: 1500,
          discountCents: 500,
          totalCents: 1000,
          shippingName: 'Ada',
          shippingPhone: '1',
          shippingAddress: 'X',
          createdAt: 1,
          updatedAt: 1,
        ));
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
          orderId: orderId,
          productId: Value(productId),
          productName: 'T',
          unitPriceCents: 2000,
          quantity: 1,
        ));
    await db.into(db.orderStatusHistory).insert(
      OrderStatusHistoryCompanion.insert(
        orderId: orderId,
        status: OrderStatus.pending,
        changedAt: 1,
      ),
    );

    await (db.delete(db.products)..where((t) => t.id.equals(productId))).go();

    final item = await db.select(db.orderItems).getSingle();
    expect(item.productId, isNull);
    expect(item.productName, 'T'); // snapshot preserved after product deletion
    expect(item.unitPriceCents, 2000);
    expect(item.quantity, 1);
  });

  test('deleting an order cascades its items and status history', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T',
          priceCents: 1000,
          discountPercent: 0,
          stock: 3,
          createdAt: 1,
          updatedAt: 1,
        ));
    final orderId = await db.into(db.orders).insert(OrdersCompanion.insert(
          orderNumber: 'ORD-000001',
          status: OrderStatus.pending,
          subtotalCents: 1000,
          discountCents: 0,
          totalCents: 1000,
          shippingName: 'Ada',
          shippingPhone: '1',
          shippingAddress: 'X',
          createdAt: 1,
          updatedAt: 1,
        ));
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
          orderId: orderId,
          productName: 'T',
          unitPriceCents: 1000,
          quantity: 1,
        ));
    await db.into(db.orderStatusHistory).insert(
      OrderStatusHistoryCompanion.insert(
        orderId: orderId,
        status: OrderStatus.pending,
        changedAt: 1,
      ),
    );

    await (db.delete(db.orders)..where((t) => t.id.equals(orderId))).go();

    expect(await db.select(db.orderItems).get(), isEmpty);
    expect(await db.select(db.orderStatusHistory).get(), isEmpty);
  });

  test('order status enum round-trips through intEnum', () async {
    await db.into(db.orders).insert(OrdersCompanion.insert(
          orderNumber: 'ORD-000001',
          status: OrderStatus.shipped,
          subtotalCents: 1000,
          discountCents: 0,
          totalCents: 1000,
          shippingName: 'Ada',
          shippingPhone: '123',
          shippingAddress: 'X',
          createdAt: 1,
          updatedAt: 1,
        ));

    final row = await db.select(db.orders).getSingle();
    expect(row.status, OrderStatus.shipped);
    expect(row.orderNumber, 'ORD-000001');
    expect(row.totalCents, 1000);
  });

  test('watch() re-emits when data changes', () async {
    final done = expectLater(
      db.select(db.categories).watch(),
      emitsInOrder([isEmpty, hasLength(1)]),
    );

    await pumpEventQueue();
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'Clothing', createdAt: 1),
        );

    await done;
  });
}

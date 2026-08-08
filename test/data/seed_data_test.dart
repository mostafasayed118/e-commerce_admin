import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/coupon.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';

void main() {
  test('seeds categories, products, coupons, orders, items and history',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await SeedData(db).seedIfNeeded();

    expect(await db.select(db.categories).get(), isNotEmpty);
    expect(await db.select(db.products).get(), isNotEmpty);
    expect(await db.select(db.coupons).get(), isNotEmpty);
    expect(await db.select(db.orders).get(), isNotEmpty);
    expect(await db.select(db.orderItems).get(), isNotEmpty);
    expect(await db.select(db.orderStatusHistory).get(), isNotEmpty);

    final meta = await (db.select(db.appMeta)..where((t) => t.id.equals(1)))
        .getSingle();
    expect(meta.seedVersion, SeedData.version);
  });

  test('seed coupons cover the demo scenarios (types + validity states)',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await SeedData(db).seedIfNeeded();

    final coupons = await db.select(db.coupons).get();
    expect(coupons, hasLength(4));
    expect(
      coupons.map((c) => c.code).toSet(),
      containsAll(['WELCOME10', 'SAVE5', 'SUMMER20', 'EXPIRED10']),
    );

    // The usage counters agree with the coupon-bearing seed orders (the
    // invariant that keeps the dashboard ranking honest).
    final couponOrders = (await db.select(db.orders).get())
        .where((o) => o.couponCode != null)
        .toList();
    final welcomeOrders =
        couponOrders.where((o) => o.couponCode == 'WELCOME10').length;
    final save5Orders = couponOrders.where((o) => o.couponCode == 'SAVE5').length;
    expect(welcomeOrders, 2);
    expect(save5Orders, 3);

    final welcome = coupons.singleWhere((c) => c.code == 'WELCOME10');
    expect(welcome.discountType, CouponDiscountType.percent);
    expect(welcome.value, 10);
    expect(welcome.minSpendCents, 3000,
        reason: 'a minimum-spend coupon for the checkout demo');
    expect(welcome.usedCount, welcomeOrders,
        reason: 'the usage counter agrees with the coupon-bearing seed orders');

    final save5 = coupons.singleWhere((c) => c.code == 'SAVE5');
    expect(save5.discountType, CouponDiscountType.fixed);
    expect(save5.value, 500);
    expect(save5.usedCount, save5Orders);
    expect(save5.maxUses, 5,
        reason: 'a usage cap so the dashboard ranking demos both bar modes '
            '(capped used/max label vs the uncapped relative bar)');
    expect(save5.usedCount <= save5.maxUses!, isTrue,
        reason: 'a demo cap must never be exhausted by the seed itself');

    final summer = coupons.singleWhere((c) => c.code == 'SUMMER20');
    expect(summer.discountType, CouponDiscountType.percent);
    expect(summer.value, 20);
    expect(summer.expiresAt, isNotNull,
        reason: 'a time-limited coupon for the expiry demo');
    expect(summer.isActive, isTrue);

    final expired = coupons.singleWhere((c) => c.code == 'EXPIRED10');
    expect(expired.expiresAt, isNotNull);
    expect(
      expired.expiresAt! < DateTime.now().millisecondsSinceEpoch,
      isTrue,
      reason: 'an already-expired code for the error demo',
    );
  });

  test('seed covers the required demo scenarios', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await SeedData(db).seedIfNeeded();

    final products = await db.select(db.products).get();
    expect(products.any((p) => p.stock == 0), isTrue,
        reason: 'an out-of-stock product for the stock badge demo');
    expect(products.any((p) => p.stock > 0 && p.stock <= 5), isTrue,
        reason: 'a low-stock product for the admin alert demo');
    expect(products.any((p) => p.discountPercent > 0), isTrue,
        reason: 'a discounted product for the pricing demo');

    final statuses = (await db.select(db.orders).get())
        .map((o) => o.status)
        .toSet();
    expect(statuses, containsAll(OrderStatus.values),
        reason: 'demo orders exist in every status for the dashboard');
  });

  test('seeded orders are internally consistent', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await SeedData(db).seedIfNeeded();

    final orders = await db.select(db.orders).get();
    final history = await db.select(db.orderStatusHistory).get();

    for (final order in orders) {
      expect(order.subtotalCents - order.discountCents, order.totalCents,
          reason: '${order.orderNumber} totals must balance');

      final timeline = history
          .where((h) => h.orderId == order.id)
          .toList()
        ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
      expect(timeline, isNotEmpty,
          reason: '${order.orderNumber} needs a status timeline');
      expect(timeline.last.status, order.status,
          reason: '${order.orderNumber} history must end at its current status');
    }
  });

  test('seed content carries Arabic variants for every row', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await SeedData(db).seedIfNeeded();

    // Every product carries an Arabic name + description (display picks by
    // viewer locale with an English fallback — Task 23 follow-up).
    for (final product in await db.select(db.products).get()) {
      expect(product.nameAr, isNotNull,
          reason: '${product.name} must have an Arabic name');
      expect(product.descriptionAr, isNotNull,
          reason: '${product.name} must have an Arabic description');
    }
    for (final category in await db.select(db.categories).get()) {
      expect(category.nameAr, isNotNull,
          reason: '${category.name} must have an Arabic label');
    }
    // Order-item snapshots carry both labels so receipts render in the
    // viewer's language.
    for (final item in await db.select(db.orderItems).get()) {
      expect(item.productNameAr, isNotNull,
          reason: '${item.productName} must snapshot its Arabic label');
    }
  });

  test('a bumped seed version reseeds without duplicating rows', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await SeedData(db).seedIfNeeded();
    final counts = (
      categories: (await db.select(db.categories).get()).length,
      products: (await db.select(db.products).get()).length,
      coupons: (await db.select(db.coupons).get()).length,
      orders: (await db.select(db.orders).get()).length,
    );

    // Simulate an install seeded by an older version: the next launch must
    // clear + reinsert (the reseed contract), never collide on unique rows.
    await db.into(db.appMeta).insertOnConflictUpdate(
          const AppMetaCompanion(id: Value(1), seedVersion: Value(1)),
        );
    await SeedData(db).seedIfNeeded();

    expect((await db.select(db.categories).get()).length, counts.categories,
        reason: 'categories must not duplicate on reseed');
    expect((await db.select(db.products).get()).length, counts.products,
        reason: 'products must not duplicate on reseed');
    expect((await db.select(db.coupons).get()).length, counts.coupons,
        reason: 'coupons must not duplicate on reseed');
    expect((await db.select(db.orders).get()).length, counts.orders,
        reason: 'orders must not duplicate on reseed');
  });

  test('seeds once across database opens (idempotent via seedVersion)', () async {
    final tempDir = await Directory.systemTemp.createTemp('seed_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    final dbFile = File('${tempDir.path}/seed.db');

    final first = AppDatabase.forTesting(NativeDatabase(dbFile));
    await SeedData(first).seedIfNeeded();
    final counts = (
      categories: (await first.select(first.categories).get()).length,
      products: (await first.select(first.products).get()).length,
      orders: (await first.select(first.orders).get()).length,
    );
    expect(counts.categories, greaterThan(0));
    await first.close();

    final second = AppDatabase.forTesting(NativeDatabase(dbFile));
    await SeedData(second).seedIfNeeded();
    expect((await second.select(second.categories).get()).length,
        counts.categories,
        reason: 'categories must not duplicate on reopen');
    expect((await second.select(second.products).get()).length,
        counts.products,
        reason: 'products must not duplicate on reopen');
    expect((await second.select(second.orders).get()).length, counts.orders,
        reason: 'orders must not duplicate on reopen');
    await second.close();
  });
}

// The `.check()` expressions reference the column getter itself — the
// documented drift pattern for CHECK constraints. The analyzer flags it as a
// recursive getter, but the cycle is broken at codegen time (build_runner
// completes, so the recursion is not real).
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../core/entities/coupon.dart';
import '../../core/entities/order_status.dart';

// NOTE on @DataClassName: drift generates a row class per table named after
// the table. We rename them to *Row so they never collide with the domain
// entities in core/entities (Product, Order, CartItem, ...). The mapper layer
// converts Row -> entity.

/// Product groupings.
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()(); // implicit primary key
  TextColumn get name => text().unique()();

  /// Optional Arabic label. `null` = English-only (the UI falls back to
  /// [name]). Admin-created categories can carry one; seed data always does.
  TextColumn get nameAr => text().nullable()();
  IntColumn get createdAt => integer()(); // epoch ms
}

/// Sellable products. Money columns are integer cents (Decision C).
@TableIndex(name: 'idx_products_category', columns: {#categoryId})
@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// NO ACTION (drift default) — with foreign_keys=ON this is enforced
  /// immediately, functionally equivalent to RESTRICT here: a category with
  /// products cannot be deleted.
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Optional Arabic name/description. `null` = English-only (the UI falls
  /// back to [name]/[description]). Seed data carries them; admin-created
  /// products can too (the form's optional Arabic fields).
  TextColumn get nameAr => text().nullable()();
  TextColumn get descriptionAr => text().nullable()();
  IntColumn get priceCents =>
      integer().check(priceCents.isBiggerOrEqualValue(0))();
  IntColumn get discountPercent => integer().check(
        discountPercent.isBiggerOrEqualValue(0) &
            discountPercent.isSmallerOrEqualValue(100),
      )();
  IntColumn get stock => integer().check(stock.isBiggerOrEqualValue(0))();

  /// Relative path inside the app documents dir; null = no image.
  TextColumn get imagePath => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Promo codes. Validation rules (active/expiry/usage/min-spend math) live in
/// [Coupon.applyTo] — the DB only guarantees the shape of the rows.
@DataClassName('CouponRow')
class Coupons extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Normalized uppercase code, unique.
  TextColumn get code => text().unique()();
  IntColumn get discountType => intEnum<CouponDiscountType>()();

  /// Percent (1-100) or fixed cents (> 0), depending on [discountType].
  IntColumn get value => integer().check(value.isBiggerThanValue(0))();
  IntColumn get minSpendCents => integer()
      .withDefault(const Constant(0))
      .check(minSpendCents.isBiggerOrEqualValue(0))();

  /// Epoch ms; null = never expires.
  IntColumn get expiresAt => integer().nullable()();

  /// Usage cap; null = unlimited.
  IntColumn get maxUses => integer().nullable()();
  IntColumn get usedCount => integer()
      .withDefault(const Constant(0))
      .check(usedCount.isBiggerOrEqualValue(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
}

/// Customer reviews & star ratings, one row per submission.
///
/// Moderation lives at the data boundary: [isApproved] defaults to false and
/// the repository forces it on write, so a review is never storefront-visible
/// until an admin approves it. The storefront reads only approved rows;
/// the admin moderation screen reads all of them.
@TableIndex(name: 'idx_reviews_product', columns: {#productId})
@DataClassName('ProductReviewRow')
class ProductReviews extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// CASCADE — deleting a product removes its reviews automatically.
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get rating => integer().check(
        rating.isBiggerOrEqualValue(1) & rating.isSmallerOrEqualValue(5),
      )();
  TextColumn get reviewerName => text()();
  TextColumn get comment => text().withDefault(const Constant(''))();
  BoolColumn get isApproved => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
}

/// Wishlist contents: one row per saved product, keyed by product id.
/// CASCADE — deleting a product removes it from wishlists automatically.
@DataClassName('WishlistItemRow')
class WishlistItems extends Table {
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {productId};
}

/// Cart contents: one row per product, keyed by product id.
@DataClassName('CartItemRow')
class CartItems extends Table {
  /// CASCADE — deleting a product removes it from carts automatically.
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get quantity => integer().check(quantity.isBiggerThanValue(0))();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {productId};
}

/// Orders with snapshot totals captured at purchase time (Decision E).
///
/// The DB only guarantees non-negative amounts; the consistency invariant
/// `subtotal - discount == total` is computed in the domain/repository at
/// write time (deliberate boundary — see PLAN).
@TableIndex(name: 'idx_orders_status', columns: {#status})
@DataClassName('OrderRow')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text().unique()();
  IntColumn get status => intEnum<OrderStatus>()();
  IntColumn get subtotalCents =>
      integer().check(subtotalCents.isBiggerOrEqualValue(0))();
  IntColumn get discountCents =>
      integer().check(discountCents.isBiggerOrEqualValue(0))();
  IntColumn get totalCents =>
      integer().check(totalCents.isBiggerOrEqualValue(0))();
  TextColumn get shippingName => text()();
  TextColumn get shippingPhone => text()();
  TextColumn get shippingAddress => text()();

  /// Snapshot of the applied promo code, if any (Decision E — the receipt
  /// survives later coupon edits/deletes).
  TextColumn get couponCode => text().nullable()();

  /// The coupon's contribution to [discountCents]; 0 when no coupon was
  /// applied. Kept separate so the receipt can show "Savings" vs "Coupon".
  IntColumn get couponDiscountCents => integer()
      .withDefault(const Constant(0))
      .check(couponDiscountCents.isBiggerOrEqualValue(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Order lines. Name/price/discount are snapshots so history survives
/// product edits and deletions (product FK is SET NULL on delete).
@TableIndex(name: 'idx_order_items_order', columns: {#orderId})
@DataClassName('OrderItemRow')
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// CASCADE — deleting an order removes its lines.
  IntColumn get orderId =>
      integer().references(Orders, #id, onDelete: KeyAction.cascade)();

  /// SET NULL — deleting a product keeps the line, the reference goes null.
  IntColumn get productId => integer()
      .references(Products, #id, onDelete: KeyAction.setNull)
      .nullable()();
  TextColumn get productName => text()();

  /// Snapshot of the product's Arabic label at purchase time (nullable: the
  /// shopper's locale or the product's data may not have one). The receipt
  /// renders whichever label matches the *viewer's* locale — the same stored
  /// order displays English to an English admin and Arabic to an Arabic
  /// customer.
  TextColumn get productNameAr => text().nullable()();
  IntColumn get unitPriceCents =>
      integer().check(unitPriceCents.isBiggerOrEqualValue(0))();
  IntColumn get discountPercent => integer()
      .withDefault(const Constant(0))
      .check(
        discountPercent.isBiggerOrEqualValue(0) &
            discountPercent.isSmallerOrEqualValue(100),
      )();
  IntColumn get quantity => integer().check(quantity.isBiggerThanValue(0))();
}

/// The status timeline: one row per transition, timestamped at write time.
@TableIndex(name: 'idx_status_history_order', columns: {#orderId})
@DataClassName('OrderStatusHistoryRow')
class OrderStatusHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// CASCADE — deleting an order removes its history.
  IntColumn get orderId =>
      integer().references(Orders, #id, onDelete: KeyAction.cascade)();
  IntColumn get status => intEnum<OrderStatus>()();
  IntColumn get changedAt => integer()(); // epoch ms
}

/// Single-row local customer profile (id is always 1).
@DataClassName('ProfileRow')
class Profile extends Table {
  // CHECK (id = 1): guards the single-row contract at the DB level.
  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get name => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row persisted UI preferences (id is always 1): the customer's
/// theme-mode and locale choices, stored as stable codes (`ThemeMode.name`
/// and the BCP-47 locale tag). The presentation layer maps code <-> widget
/// types; the DB never sees ThemeMode/Locale objects.
@DataClassName('UiPrefsRow')
class UiPrefs extends Table {
  // CHECK (id = 1): guards the single-row contract at the DB level.
  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get themeMode => text().nullable()();
  TextColumn get localeCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row admin settings: salted PIN hash (Decision B — Option 2).
@DataClassName('AdminSettingsRow')
class AdminSettings extends Table {
  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get pinHash => text()();
  TextColumn get pinSalt => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row seeding bookkeeping (id is always 1). Decouples seed versions
/// from schema versions: reseeding does not require a migration.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  IntColumn get id => integer().check(id.equals(1))();
  IntColumn get seedVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

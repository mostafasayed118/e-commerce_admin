import 'package:drift/drift.dart';

import '../../core/entities/coupon.dart';
import '../../core/entities/order_status.dart';
import 'app_database.dart';

/// Demo data for the app's first launch, so every screen is demoable
/// immediately (spec A6).
///
/// Idempotency is tracked in [AppMeta.seedVersion]: seeding runs only when the
/// stored version is older than [version]. Bumping [version] reseeds existing
/// installs *without* a schema migration — deliberately decoupled from
/// `schemaVersion` (see PLAN, risks section). To make that contract real, the
/// seed clears its own tables before inserting, so a re-seed never collides
/// with the previous dataset's unique rows. User-owned data (profile, PIN,
/// UI prefs) is never touched.
///
/// Content is bilingual: every category, product, and demo order item carries
/// an Arabic variant ([nameAr]/[descriptionAr]/[productNameAr]) alongside the
/// canonical English text. The UI picks by the viewer's locale with an
/// English fallback (Task 23 follow-up: localized seed content).
class SeedData {
  const SeedData(this._db);

  final AppDatabase _db;

  /// Version of the seed dataset. Bump to refresh demo data on existing
  /// installs (assumes a demo/clean database — see class docs).
  static const int version = 4;

  /// Seeds if needed. Safe to call on every launch: the version check is a
  /// single SELECT, and the seed itself runs atomically in one transaction —
  /// a failure mid-seed writes nothing and the next launch retries.
  Future<void> seedIfNeeded() async {
    final meta = await (_db.select(_db.appMeta)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (meta != null && meta.seedVersion >= version) return;

    await _db.transaction(() async {
      // Reseed contract: a bumped version refreshes demo data on an existing
      // install. Wipe only the seed-owned tables (orders cascade their items
      // and history; products cascade cart rows) so the insert below starts
      // from a clean slate. Profile/PIN/prefs are user data — untouched.
      await _db.delete(_db.orders).go();
      await _db.delete(_db.products).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.coupons).go();
      await _db.delete(_db.productReviews).go();

      final base = DateTime(2026, 7, 1, 9).millisecondsSinceEpoch;
      final day = const Duration(days: 1).inMilliseconds;
      final hour = const Duration(hours: 1).inMilliseconds;

      // --- Demo coupons -----------------------------------------------------
      // Expiries are relative to the seed's fixed base date so the demo is
      // deterministic: SUMMER20 stays valid, EXPIRED10 stays expired.
      Future<void> insertCoupon({
        required String code,
        required CouponDiscountType type,
        required int value,
        int minSpendCents = 0,
        DateTime? expiresAt,
        int? maxUses,
        bool isActive = true,
        int usedCount = 0,
      }) {
        return _db.into(_db.coupons).insert(CouponsCompanion.insert(
              code: code,
              discountType: type,
              value: value,
              minSpendCents: Value(minSpendCents),
              expiresAt: Value(expiresAt?.millisecondsSinceEpoch),
              maxUses: Value(maxUses),
              isActive: Value(isActive),
              usedCount: Value(usedCount),
              createdAt: base,
            ));
      }

      // The seeded usage counters match the coupon-bearing orders below, so
      // the dashboard's "recent usage" and the admin list agree on day one.
      // Usage counters match the coupon-bearing orders below: WELCOME10 on
      // ORD-000001 + ORD-000002 (2), SAVE5 on ORD-000003 + ORD-000004 +
      // ORD-000006 (3) — SAVE5 tops the dashboard's ranking demo.
      await insertCoupon(
        code: 'WELCOME10',
        type: CouponDiscountType.percent,
        value: 10,
        minSpendCents: 3000,
        usedCount: 2,
      );
      await insertCoupon(
        code: 'SAVE5',
        type: CouponDiscountType.fixed,
        value: 500,
        // Capped: the dashboard's ranking bar shows 3/5 toward exhaustion,
        // next to WELCOME10's relative (uncapped) bar — both modes demoed.
        maxUses: 5,
        usedCount: 3,
      );
      await insertCoupon(
        code: 'SUMMER20',
        type: CouponDiscountType.percent,
        value: 20,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(base + 60 * day),
      );
      await insertCoupon(
        code: 'EXPIRED10',
        type: CouponDiscountType.percent,
        value: 10,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(base - 30 * day),
      );

      // --- Categories -------------------------------------------------------
      final categoryIds = <String, int>{};
      for (final name in [
        'Clothing',
        'Electronics',
        'Home & Kitchen',
        'Books',
        'Sports',
      ]) {
        categoryIds[name] = await _db.into(_db.categories).insert(
              CategoriesCompanion.insert(
                name: name,
                nameAr: Value(_categoryAr[name]),
                createdAt: base,
              ),
            );
      }

      // --- Products ---------------------------------------------------------
      Future<int> insertProduct({
        required String category,
        required String name,
        required int priceCents,
        int discountPercent = 0,
        int stock = 0,
        String description = '',
      }) {
        return _db.into(_db.products).insert(ProductsCompanion.insert(
              categoryId: categoryIds[category]!,
              name: name,
              description: Value(description),
              nameAr: Value(_productAr[name]?.$1),
              descriptionAr: Value(_productAr[name]?.$2),
              priceCents: priceCents,
              discountPercent: discountPercent,
              stock: stock,
              createdAt: base,
              updatedAt: base,
            ));
      }

      final tee =
          await insertProduct(category: 'Clothing', name: 'Classic Tee', priceCents: 2000, discountPercent: 25, stock: 25, description: 'A wardrobe staple in soft organic cotton.');
      final jacket =
          await insertProduct(category: 'Clothing', name: 'Denim Jacket', priceCents: 4500, stock: 8, description: 'Timeless denim with a tailored fit.');
      await insertProduct(category: 'Clothing', name: 'Wool Beanie', priceCents: 1200, stock: 4, description: 'Keep warm in style.');
      final belt =
          await insertProduct(category: 'Clothing', name: 'Leather Belt', priceCents: 2800, stock: 0, description: 'Full-grain leather, sadly out of stock.');

      final earbuds =
          await insertProduct(category: 'Electronics', name: 'Wireless Earbuds', priceCents: 9900, discountPercent: 15, stock: 30, description: 'Crisp sound, all-day battery.');
      await insertProduct(category: 'Electronics', name: 'USB-C Hub', priceCents: 4500, stock: 5, description: 'Seven ports, one cable.');
      final keyboard =
          await insertProduct(category: 'Electronics', name: 'Mechanical Keyboard', priceCents: 12000, stock: 15, description: 'Tactile switches, hot-swappable.');

      final mugSet =
          await insertProduct(category: 'Home & Kitchen', name: 'Ceramic Mug Set', priceCents: 2500, discountPercent: 10, stock: 40, description: 'Set of four, dishwasher safe.');
      await insertProduct(category: 'Home & Kitchen', name: 'Cast Iron Pan', priceCents: 6500, stock: 12, description: 'Seasoned, oven-safe, forever.');

      final flutterBook =
          await insertProduct(category: 'Books', name: 'Flutter in Action', priceCents: 3500, stock: 20, description: 'A practical guide to building apps.');
      final cleanArch =
          await insertProduct(category: 'Books', name: 'Clean Architecture', priceCents: 4500, discountPercent: 20, stock: 3, description: 'A craftsman guide to software structure.');

      final yogaMat =
          await insertProduct(category: 'Sports', name: 'Yoga Mat', priceCents: 2900, stock: 0, description: 'Extra grip, easy to roll.');
      final bands =
          await insertProduct(category: 'Sports', name: 'Resistance Bands', priceCents: 1500, stock: 60, description: 'Five levels of resistance.');

      // --- Demo orders ------------------------------------------------------
      // [couponCode] and [couponDiscountCents] travel as a pair (a code
      // always snapshots its discount): the receipt hides a zero-discount
      // line, so a code without a discount would silently vanish.
      Future<void> insertOrder({
        required String number,
        required OrderStatus status,
        required int subtotalCents,
        required int discountCents,
        required int totalCents,
        required String name,
        required String phone,
        required String address,
        required int placedAt,
        String? couponCode,
        int couponDiscountCents = 0,
        required List<({int? productId, String productName, int unitPriceCents, int discountPercent, int quantity})> items,
        required List<({OrderStatus status, int changedAt})> history,
      }) async {
        final orderId = await _db.into(_db.orders).insert(OrdersCompanion.insert(
              orderNumber: number,
              status: status,
              subtotalCents: subtotalCents,
              discountCents: discountCents,
              totalCents: totalCents,
              couponCode: Value(couponCode),
              couponDiscountCents: Value(couponDiscountCents),
              shippingName: name,
              shippingPhone: phone,
              shippingAddress: address,
              createdAt: placedAt,
              updatedAt: history.last.changedAt,
            ));
        for (final item in items) {
          await _db.into(_db.orderItems).insert(OrderItemsCompanion.insert(
                orderId: orderId,
                // productId is Value<int?> — Value() accepts null, so no ternary.
                productId: Value(item.productId),
                productName: item.productName,
                productNameAr: Value(_productAr[item.productName]?.$1),
                unitPriceCents: item.unitPriceCents,
                discountPercent: Value(item.discountPercent),
                quantity: item.quantity,
              ));
        }
        for (final entry in history) {
          await _db.into(_db.orderStatusHistory).insert(
            OrderStatusHistoryCompanion.insert(
              orderId: orderId,
              status: entry.status,
              changedAt: entry.changedAt,
            ),
          );
        }
      }

      // Every order satisfies subtotal - discount == total (tested).
      await insertOrder(
        number: 'ORD-000001',
        status: OrderStatus.delivered,
        subtotalCents: 6800,
        // WELCOME10 (10%, min $30): line savings 1000 → eligible 5800 → 580.
        discountCents: 1580,
        totalCents: 5220,
        couponCode: 'WELCOME10',
        couponDiscountCents: 580,
        name: 'Amira Hassan',
        phone: '0100 000 0001',
        address: '14 Nile St, Cairo',
        placedAt: base - 6 * day,
        items: [
          (productId: tee, productName: 'Classic Tee', unitPriceCents: 2000, discountPercent: 25, quantity: 2),
          (productId: belt, productName: 'Leather Belt', unitPriceCents: 2800, discountPercent: 0, quantity: 1),
        ],
        history: [
          (status: OrderStatus.pending, changedAt: base - 6 * day),
          (status: OrderStatus.confirmed, changedAt: base - 6 * day + hour),
          (status: OrderStatus.shipped, changedAt: base - 5 * day),
          (status: OrderStatus.delivered, changedAt: base - 4 * day),
        ],
      );

      await insertOrder(
        number: 'ORD-000002',
        status: OrderStatus.shipped,
        subtotalCents: 9900,
        // WELCOME10: line savings 1485 → eligible 8415 → 10% = 841.
        discountCents: 2326,
        totalCents: 7574,
        couponCode: 'WELCOME10',
        couponDiscountCents: 841,
        name: 'Karim Adel',
        phone: '0100 000 0002',
        address: '8 Tahrir Sq, Cairo',
        placedAt: base - 2 * day,
        items: [
          (productId: earbuds, productName: 'Wireless Earbuds', unitPriceCents: 9900, discountPercent: 15, quantity: 1),
        ],
        history: [
          (status: OrderStatus.pending, changedAt: base - 2 * day),
          (status: OrderStatus.confirmed, changedAt: base - 2 * day + hour),
          (status: OrderStatus.shipped, changedAt: base - day),
        ],
      );

      await insertOrder(
        number: 'ORD-000003',
        status: OrderStatus.confirmed,
        subtotalCents: 17000,
        // SAVE5 (fixed $5) on top of the 500 line savings.
        discountCents: 1000,
        totalCents: 16000,
        couponCode: 'SAVE5',
        couponDiscountCents: 500,
        name: 'Lina Fathy',
        phone: '0100 000 0003',
        address: '22 Corniche Rd, Alexandria',
        placedAt: base - day + 2 * hour,
        items: [
          (productId: keyboard, productName: 'Mechanical Keyboard', unitPriceCents: 12000, discountPercent: 0, quantity: 1),
          (productId: mugSet, productName: 'Ceramic Mug Set', unitPriceCents: 2500, discountPercent: 10, quantity: 2),
        ],
        history: [
          (status: OrderStatus.pending, changedAt: base - day + 2 * hour),
          (status: OrderStatus.confirmed, changedAt: base - day + 3 * hour),
        ],
      );

      await insertOrder(
        number: 'ORD-000004',
        status: OrderStatus.pending,
        subtotalCents: 5900,
        // SAVE5 (fixed $5): the newest order shows in the dashboard's
        // "recent coupon usage" first.
        discountCents: 500,
        totalCents: 5400,
        couponCode: 'SAVE5',
        couponDiscountCents: 500,
        name: 'Omar Khaled',
        phone: '0100 000 0004',
        address: '3 Zamalek St, Cairo',
        placedAt: base - 3 * hour,
        items: [
          (productId: yogaMat, productName: 'Yoga Mat', unitPriceCents: 2900, discountPercent: 0, quantity: 1),
          (productId: bands, productName: 'Resistance Bands', unitPriceCents: 1500, discountPercent: 0, quantity: 2),
        ],
        history: [
          (status: OrderStatus.pending, changedAt: base - 3 * hour),
        ],
      );

      await insertOrder(
        number: 'ORD-000005',
        status: OrderStatus.cancelled,
        subtotalCents: 4500,
        discountCents: 0,
        totalCents: 4500,
        name: 'Sara Nabil',
        phone: '0100 000 0005',
        address: '5 Dokki St, Giza',
        placedAt: base - 8 * day,
        items: [
          (productId: jacket, productName: 'Denim Jacket', unitPriceCents: 4500, discountPercent: 0, quantity: 1),
        ],
        history: [
          (status: OrderStatus.pending, changedAt: base - 8 * day),
          (status: OrderStatus.cancelled, changedAt: base - 7 * day),
        ],
      );

      // --- Demo reviews ----------------------------------------------------
      // Approved reviews drive the storefront section (Classic Tee carries
      // four, averaging 4.5); Sara Nabil's 2-star submission is deliberately
      // left HIDDEN so the admin moderation screen has a pending row to
      // approve — the seed demos both halves of the moderation contract.
      Future<void> insertReview({
        required int productId,
        required int rating,
        required String reviewerName,
        required String comment,
        required int at,
        bool isApproved = true,
      }) {
        return _db.into(_db.productReviews).insert(
          ProductReviewsCompanion.insert(
            productId: productId,
            rating: rating,
            reviewerName: reviewerName,
            comment: Value(comment),
            isApproved: Value(isApproved),
            createdAt: at,
          ),
        );
      }

      await insertReview(
        productId: tee,
        rating: 5,
        reviewerName: 'Amira Hassan',
        comment: 'Soft and true to size — my new favorite tee.',
        at: base - 2 * day,
      );
      await insertReview(
        productId: tee,
        rating: 4,
        reviewerName: 'Karim Adel',
        comment: 'Great quality for the price.',
        at: base - 3 * day,
      );
      await insertReview(
        productId: tee,
        rating: 5,
        reviewerName: 'Lina Fathy',
        comment: 'The cotton feels premium. Would buy again.',
        at: base - 5 * day,
      );
      await insertReview(
        productId: tee,
        rating: 4,
        reviewerName: 'Omar Khaled',
        comment: 'Nice fit, washes well.',
        at: base - 7 * day,
      );
      // The pending (hidden) review — the moderation demo.
      await insertReview(
        productId: tee,
        rating: 2,
        reviewerName: 'Sara Nabil',
        comment: 'Runs small for me.',
        at: base - day,
        isApproved: false,
      );

      await insertReview(
        productId: earbuds,
        rating: 5,
        reviewerName: 'Hany Ibrahim',
        comment: 'Crisp sound, the battery really lasts all day.',
        at: base - 4 * day,
      );
      await insertReview(
        productId: earbuds,
        rating: 4,
        reviewerName: 'Sara Nabil',
        comment: 'Good for the price, bass is a bit light.',
        at: base - 6 * day,
      );
      await insertReview(
        productId: flutterBook,
        rating: 5,
        reviewerName: 'Karim Adel',
        comment: 'The clearest Flutter guide I have read.',
        at: base - 9 * day,
      );
      await insertReview(
        productId: yogaMat,
        rating: 5,
        reviewerName: 'Lina Fathy',
        comment: 'Excellent grip — no slipping in hot yoga.',
        at: base - 10 * day,
      );

      await insertOrder(
        number: 'ORD-000006',
        status: OrderStatus.delivered,
        subtotalCents: 8000,
        // SAVE5 (fixed $5) on top of the 900 line savings.
        discountCents: 1400,
        totalCents: 6600,
        couponCode: 'SAVE5',
        couponDiscountCents: 500,
        name: 'Hany Ibrahim',
        phone: '0100 000 0006',
        address: '19 Nasr City, Cairo',
        placedAt: base - 10 * day,
        items: [
          (productId: flutterBook, productName: 'Flutter in Action', unitPriceCents: 3500, discountPercent: 0, quantity: 1),
          (productId: cleanArch, productName: 'Clean Architecture', unitPriceCents: 4500, discountPercent: 20, quantity: 1),
        ],
        history: [
          (status: OrderStatus.pending, changedAt: base - 10 * day),
          (status: OrderStatus.confirmed, changedAt: base - 10 * day + hour),
          (status: OrderStatus.shipped, changedAt: base - 9 * day),
          (status: OrderStatus.delivered, changedAt: base - 8 * day),
        ],
      );

      await _db.into(_db.appMeta).insertOnConflictUpdate(
            const AppMetaCompanion(
              id: Value(1),
              seedVersion: Value(version),
            ),
          );
    });
  }

  /// Arabic category labels, keyed by the canonical English name.
  static const Map<String, String> _categoryAr = {
    'Clothing': 'ملابس',
    'Electronics': 'إلكترونيات',
    'Home & Kitchen': 'المنزل والمطبخ',
    'Books': 'كتب',
    'Sports': 'رياضة',
  };

  /// Arabic (name, description) pairs for the seeded products, keyed by the
  /// canonical English name — the single source for both the product rows and
  /// the order-item snapshots, so the two can never drift apart.
  static const Map<String, (String, String)> _productAr = {
    'Classic Tee': ('تيشيرت كلاسيك', 'قطعة أساسية من قطن عضوي ناعم.'),
    'Denim Jacket': ('جاكيت دنيم', 'دنيم خالد بقصّة مصمّمة بدقة.'),
    'Wool Beanie': ('قبعة صوف', 'ابقَ دافئًا بأناقة.'),
    'Leather Belt': ('حزام جلدي', 'جلد فاخر، للأسف نفد من المخزون.'),
    'Wireless Earbuds': ('سماعات لاسلكية', 'صوت نقي وبطارية تدوم طوال اليوم.'),
    'USB-C Hub': ('موزّع USB-C', 'سبعة منافذ بكابل واحد.'),
    'Mechanical Keyboard': ('لوحة مفاتيح ميكانيكية', 'مفاتيح لمسية قابلة للتبديل السريع.'),
    'Ceramic Mug Set': ('طقم أكواب سيراميك', 'طقم من أربعة، آمن للغسالة.'),
    'Cast Iron Pan': ('مقلاة من حديد الزهر', 'متبلّة، آمنة للفرن، تدوم للأبد.'),
    'Flutter in Action': ('فلاتر في العمل', 'دليل عملي لبناء التطبيقات.'),
    'Clean Architecture': ('العمارة النظيفة', 'دليل حِرفي لبنية البرمجيات.'),
    'Yoga Mat': ('سجادة يوجا', 'قبضة إضافية وسهلة اللف.'),
    'Resistance Bands': ('أربطة المقاومة', 'خمس مستويات من المقاومة.'),
  };
}

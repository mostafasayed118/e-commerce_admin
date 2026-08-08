import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/utils/order_receipt_pdf.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/orders/order_receipt_data.dart';

/// The order every case resolves: 10% off a 2900c item ×2, plus a $3 coupon
/// on top of $6 of line savings (subtotal 5900, total discount 900, paid
/// 5000) — the same shape order_detail_view_test uses.
Order _order() => Order(
      id: 1,
      orderNumber: 'ORD-000004',
      status: OrderStatus.pending,
      subtotalCents: 5900,
      discountCents: 900,
      totalCents: 5000,
      couponCode: 'SAVE10',
      couponDiscountCents: 300,
      shipping: const ShippingInfo(
        name: 'Omar Khaled',
        phone: '0100 000 0004',
        address: '3 Zamalek St, Cairo',
      ),
      items: const [
        OrderItem(
          id: 1,
          orderId: 1,
          productId: 12,
          productName: 'Yoga Mat',
          productNameAr: 'سجادة يوجا',
          unitPriceCents: 2900,
          discountPercent: 10,
          quantity: 2,
        ),
      ],
      statusHistory: const [],
      createdAt: DateTime(2026, 7, 1, 6),
    );

/// Resolves the order inside a pumped app so the context extensions
/// (`context.l10n`, `context.formatCents`, …) behave exactly as on screen.
Future<ReceiptData> resolve(
  WidgetTester tester,
  Locale locale,
) async {
  late ReceiptData result;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          result = buildOrderReceiptData(context, _order());
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

void main() {
  testWidgets('resolves every receipt field in English', (tester) async {
    final data = await resolve(tester, const Locale('en'));

    expect(data.title, 'Order receipt');
    expect(data.orderNumber, 'ORD-000004');
    expect(data.placed, 'Placed 1 Jul 2026, 06:00');
    expect(data.statusField, 'Status');
    expect(data.statusLabel, 'Pending');

    expect(data.deliverTo, 'Deliver to');
    expect(data.customerName, 'Omar Khaled');
    expect(data.customerPhone, '0100 000 0004');

    expect(data.itemsTitle, 'Items');
    expect(data.lines, hasLength(1));
    final line = data.lines.single;
    expect(line.name, 'Yoga Mat');
    expect(line.detail, '2 × \$26.10 (10% off)');
    expect(line.amount, r'$52.20');

    expect(data.subtotalLabel, 'Subtotal');
    expect(data.subtotal, r'$59.00');
    expect(data.savingsLabel, 'Savings');
    expect(data.savings, r'-$6.00'); // 900 - 300 coupon = 600 line savings
    expect(data.couponLabel, 'Coupon (SAVE10)');
    expect(data.coupon, r'-$3.00');
    expect(data.totalLabel, 'Total');
    expect(data.total, r'$50.00');
  });

  testWidgets(
      'Arabic: localized labels, Eastern digits, canonical order number',
      (tester) async {
    final data = await resolve(tester, const Locale('ar'));

    expect(data.title, 'إيصال الطلب');
    // Identifiers stay canonical (the same convention as the screens).
    expect(data.orderNumber, 'ORD-000004');
    expect(data.placed, contains('يوليو'));
    expect(data.placed, contains('٢٠٢٦'));
    expect(data.statusField, 'الحالة');
    expect(data.statusLabel, 'قيد الانتظار');

    expect(data.customerName, 'Omar Khaled'); // a name, not display data
    expect(data.customerPhone, '٠١٠٠ ٠٠٠ ٠٠٠٤'); // display data → converts

    final line = data.lines.single;
    expect(line.name, 'سجادة يوجا');
    expect(line.detail, contains('٢'));
    expect(line.detail, contains('١٠'));

    // intl's ar currency keeps the Western decimal point: '‏٥٩.٠٠ $' (the
    // digits convert, the separator does not) — assert the digits only.
    expect(data.subtotal, contains('٥٩'));
    expect(data.coupon, contains('٣'));
    expect(data.total, contains('٥٠'));
  });

  testWidgets('no coupon and no line savings omit those rows',
      (tester) async {
    final order = Order(
      id: 2,
      orderNumber: 'ORD-000005',
      status: OrderStatus.pending,
      subtotalCents: 1000,
      discountCents: 0,
      totalCents: 1000,
      shipping: const ShippingInfo(name: 'X', phone: '0', address: 'Y'),
      items: const [],
      statusHistory: const [],
      createdAt: DateTime(2026, 7, 1),
    );
    late ReceiptData result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = buildOrderReceiptData(context, order);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(result.savings, isNull);
    expect(result.coupon, isNull);
    expect(result.couponLabel, isNull);
    expect(result.placed, 'Placed 1 Jul 2026, 00:00');
  });

  test('loadReceiptFont: Helvetica for en, the bundled Arabic font for ar',
      () async {
    final en = await loadReceiptFont('en');
    expect(en, isNotNull); // built-in — nothing to assert beyond type

    final ar = await loadReceiptFont('ar');
    expect(ar, isNotNull);
    // Loaded from the real asset, so this doubles as an asset-declaration
    // check: if pubspec forgot the font, rootBundle.load would throw.
  });
}

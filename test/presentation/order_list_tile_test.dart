import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/orders/order_list_tile.dart';

Future<void> pumpTile(WidgetTester tester, Order order, {VoidCallback? onTap}) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: OrderListTile(order: order, onTap: onTap)),
      ),
    );

Order order({int itemCount = 2}) => Order(
      id: 1,
      orderNumber: 'ORD-000001',
      status: OrderStatus.shipped,
      subtotalCents: 6800,
      discountCents: 1000,
      totalCents: 5800,
      shipping: const ShippingInfo(
        name: 'Amira Hassan',
        phone: '0100 000 0001',
        address: '14 Nile St, Cairo',
      ),
      items: [
        for (var i = 0; i < itemCount; i++)
          OrderItem(
            id: i,
            orderId: 1,
            productId: i,
            productName: 'Item $i',
            unitPriceCents: 1000,
            quantity: 1,
          ),
      ],
      statusHistory: const [],
      createdAt: DateTime(2026, 8, 5),
    );

void main() {
  testWidgets('renders the order number, status chip, and subtitle parts',
      (WidgetTester tester) async {
    await pumpTile(tester, order());

    expect(find.text('ORD-000001'), findsOneWidget);
    // Status chip label (localized).
    expect(find.text('Shipped'), findsOneWidget);
    // Subtitle: date · item count · total.
    expect(find.text('5 Aug 2026 · 2 items · \$58.00'), findsOneWidget);
  });

  testWidgets('item count pluralizes to the singular form for one item',
      (WidgetTester tester) async {
    await pumpTile(tester, order(itemCount: 1));

    expect(find.text('5 Aug 2026 · 1 item · \$58.00'), findsOneWidget);
  });

  testWidgets('a missing createdAt omits the date part from the subtitle',
      (WidgetTester tester) async {
    final withoutDate = Order(
      id: 2,
      orderNumber: 'ORD-000002',
      status: OrderStatus.pending,
      subtotalCents: 1000,
      discountCents: 0,
      totalCents: 1000,
      shipping: const ShippingInfo(name: 'X', phone: '0', address: 'Y'),
      items: const [],
      statusHistory: const [],
    );
    await pumpTile(tester, withoutDate);

    // No date part; the empty order has 0 items.
    expect(find.text('0 items · \$10.00'), findsOneWidget);
  });

  testWidgets('tapping the tile fires onTap', (WidgetTester tester) async {
    var tapped = 0;
    await pumpTile(tester, order(), onTap: () => tapped++);

    await tester.tap(find.text('ORD-000001'));
    expect(tapped, 1);
  });
}

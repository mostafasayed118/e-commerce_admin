import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/orders/order_detail_view.dart';
import 'package:shop_admin/presentation/features/orders/status_visuals.dart';

Future<void> pumpView(WidgetTester tester, Order order, {Widget? actions}) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: OrderDetailView(order: order, actions: actions)),
      ),
    );

Order sampleOrder() => Order(
      id: 1,
      orderNumber: 'ORD-000004',
      status: OrderStatus.pending,
      subtotalCents: 5900,
      discountCents: 900,
      totalCents: 5000,
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
      statusHistory: [
        OrderStatusEntry(
          status: OrderStatus.pending,
          changedAt: DateTime(2026, 7, 1, 6),
        ),
      ],
      createdAt: DateTime(2026, 7, 1, 6),
    );

void main() {
  testWidgets('renders the header: number, status chip, and placed date',
      (WidgetTester tester) async {
    await pumpView(tester, sampleOrder());

    expect(find.text('ORD-000004'), findsOneWidget);
    // The localized status chip (scoped: the timeline also renders the
    // status text for its single entry).
    expect(
      find.descendant(
        of: find.byType(StatusChip),
        matching: find.text('Pending'),
      ),
      findsOneWidget,
    );
    // "Placed 1 Jul 2026, 06:00"
    expect(find.text('Placed 1 Jul 2026, 06:00'), findsOneWidget);
  });

  testWidgets('renders the shipping snapshot', (WidgetTester tester) async {
    await pumpView(tester, sampleOrder());

    // SectionHeader renders its label in ALL CAPS.
    expect(find.text('DELIVER TO'), findsOneWidget);
    expect(find.text('Omar Khaled'), findsOneWidget);
    expect(find.text('0100 000 0004'), findsOneWidget);
    expect(find.text('3 Zamalek St, Cairo'), findsOneWidget);
  });

  testWidgets('renders items and the totals incl. a savings row',
      (WidgetTester tester) async {
    await pumpView(tester, sampleOrder());

    expect(find.text('ITEMS'), findsOneWidget);
    expect(find.text('Yoga Mat'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(r'$59.00'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text(r'-$9.00'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(r'$50.00'), findsOneWidget);
  });

  testWidgets('renders the status timeline section', (WidgetTester tester) async {
    await pumpView(tester, sampleOrder());

    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets); // chip + timeline entry
  });

  testWidgets('renders the coupon line separately from line savings',
      (WidgetTester tester) async {
    final order = Order(
      id: 2,
      orderNumber: 'ORD-000007',
      status: OrderStatus.pending,
      subtotalCents: 5000,
      discountCents: 900, // 600 line savings + 300 coupon
      totalCents: 4100,
      couponCode: 'SAVE10',
      couponDiscountCents: 300,
      shipping: const ShippingInfo(name: 'X', phone: '0', address: 'Y'),
      items: const [
        OrderItem(
          id: 1,
          orderId: 2,
          productId: 1,
          productName: 'Mug',
          unitPriceCents: 2500,
          discountPercent: 0,
          quantity: 2,
        ),
      ],
      statusHistory: const [],
      createdAt: DateTime(2026, 7, 2),
    );
    await pumpView(tester, order);

    // The receipt breaks the discount into its two sources: line savings
    // and the coupon (Decision E — the snapshot survives later edits).
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text(r'-$6.00'), findsOneWidget);
    expect(find.text('Coupon (SAVE10)'), findsOneWidget);
    expect(find.text(r'-$3.00'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(r'$41.00'), findsOneWidget);
  });

  testWidgets('an empty history shows the no-history message',
      (WidgetTester tester) async {
    final order = Order(
      id: 1,
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
    await pumpView(tester, order);

    expect(find.text('No status history yet.'), findsOneWidget);
  });

  testWidgets('renders the optional actions widget after the timeline',
      (WidgetTester tester) async {
    await pumpView(
      tester,
      sampleOrder(),
      actions: const FilledButton(
        onPressed: null,
        child: Text('Mark as confirmed'),
      ),
    );

    expect(find.text('Mark as confirmed'), findsOneWidget);
  });

  testWidgets('item names render in the viewer locale (Arabic)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: OrderDetailView(order: sampleOrder())),
      ),
    );

    expect(find.text('سجادة يوجا'), findsOneWidget);
  });

  testWidgets(
      'Arabic: the phone converts to Eastern digits; the order number '
      'stays canonical', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: OrderDetailView(order: sampleOrder())),
      ),
    );

    // Phone is display data — converts (same as prices/dates).
    expect(find.text('٠١٠٠ ٠٠٠ ٠٠٠٤'), findsOneWidget);
    expect(find.text('0100 000 0004'), findsNothing);
    // Order number is an identifier — rendered canonically, like coupon codes.
    expect(find.text('ORD-000004'), findsOneWidget);
  });
}


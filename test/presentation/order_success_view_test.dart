import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/checkout/order_success_view.dart';

Future<void> pumpView(WidgetTester tester, Order order, {Locale? locale}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrderSuccessView(order: order),
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
      statusHistory: const [],
      createdAt: DateTime(2026, 7, 1, 6),
    );

void main() {
  testWidgets('renders the placed summary with the order number',
      (WidgetTester tester) async {
    await pumpView(tester, sampleOrder());

    expect(find.text('Order placed!'), findsOneWidget);
    // Number + total, with the canonical order number preserved.
    expect(find.text(r'Order ORD-000004 · $50.00'), findsOneWidget);
    expect(
      find.text('We will call 0100 000 0004 to confirm delivery details.'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic: phone converts to Eastern digits; order number stays '
      'canonical', (WidgetTester tester) async {
    await pumpView(tester, sampleOrder(), locale: const Locale('ar'));

    // The phone (display data) converts; the identifier does not.
    // textContaining with the converted digits only: robust to ARB rewording.
    expect(find.textContaining('٠١٠٠ ٠٠٠ ٠٠٠٤'), findsOneWidget);
    expect(find.textContaining('0100 000 0004'), findsNothing);
    // The summary keeps the canonical order number (Western digits); the
    // total is already Eastern via formatCents. The exact full string is
    // fragile (intl's ar currency adds bidi marks), so match stable parts.
    expect(find.textContaining('ORD-000004'), findsOneWidget);
    expect(find.textContaining('٥٠.٠٠'), findsOneWidget); // Eastern total
  });

  testWidgets('back to shop navigates to the catalog root',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/checkout/success',
      routes: [
        GoRoute(
          path: '/checkout/success',
          builder: (context, state) => OrderSuccessView(order: sampleOrder()),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('catalog'))),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));

    await tester.tap(find.text('Back to shop'));
    await tester.pumpAndSettle();

    expect(find.text('catalog'), findsOneWidget);
  });
}

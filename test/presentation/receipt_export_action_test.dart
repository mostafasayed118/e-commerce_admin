import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/orders/receipt_export_action.dart';

Order _order() => Order(
      id: 1,
      orderNumber: 'ORD-000004',
      status: OrderStatus.pending,
      subtotalCents: 5900,
      discountCents: 900,
      totalCents: 5000,
      shipping: const ShippingInfo(name: 'X', phone: '0', address: 'Y'),
      items: const [],
      statusHistory: const [],
      createdAt: DateTime(2026, 7, 1),
    );

Future<void> pumpAction(WidgetTester tester, {Locale? locale}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: [ReceiptExportAction(order: _order())],
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

void main() {
  testWidgets('renders the download icon with the localized tooltip, enabled',
      (WidgetTester tester) async {
    await pumpAction(tester);

    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(find.byTooltip('Download receipt'), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    // Enabled: the order is present. The tap is not exercised — the native
    // save dialog is a platform boundary outside widget tests; the export
    // flow itself is unit-tested (order_receipt_pdf_test).
    expect(button.onPressed, isNotNull);
  });

  testWidgets('the tooltip is localized in Arabic', (WidgetTester tester) async {
    await pumpAction(tester, locale: const Locale('ar'));

    expect(find.byTooltip('تنزيل الإيصال'), findsOneWidget);
  });
}

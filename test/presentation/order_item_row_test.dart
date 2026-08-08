import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/orders/widgets/order_item_row.dart';

Future<void> pumpRow(WidgetTester tester, OrderItem item, {Locale? locale}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: OrderItemRow(item: item)),
      ),
    );

void main() {
  final tee = OrderItem(
    id: 1,
    orderId: 1,
    productId: 1,
    productName: 'Classic Tee',
    unitPriceCents: 2000,
    discountPercent: 25,
    quantity: 2,
  );

  testWidgets('shows quantity, discounted unit price and the discount note',
      (WidgetTester tester) async {
    await pumpRow(tester, tee);

    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text(r'2 × $15.00 (25% off)'), findsOneWidget);
    expect(find.text(r'$30.00'), findsOneWidget); // line total
  });

  testWidgets('Arabic renders Eastern digits for the quantity and percent',
      (WidgetTester tester) async {
    await pumpRow(tester, tee, locale: const Locale('ar'));

    // intl's ar currency pattern carries bidi marks around the amount, so
    // assert the stable parts rather than the exact bytes (like money_test).
    expect(find.textContaining('٢ ×'), findsOneWidget);
    expect(find.textContaining('١٥.٠٠'), findsOneWidget); // unit price
    expect(find.textContaining('خصم ٢٥%'), findsOneWidget);
    expect(find.textContaining('٣٠.٠٠'), findsOneWidget); // line total
    expect(find.textContaining('15.00'), findsNothing);
  });
}

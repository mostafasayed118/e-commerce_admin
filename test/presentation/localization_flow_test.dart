import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/app.dart';
import 'package:shop_admin/presentation/features/orders/order_detail_view.dart';
import 'package:shop_admin/presentation/locale/locale_cubit.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// Task 23: the language switch must (1) swap every visible string to the
/// chosen locale and (2) flip the layout direction for Arabic — both are
/// driven by the single DI-owned LocaleCubit flowing into MaterialApp.
void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    await tester.pumpWidget(const ShopAdminApp());
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  TextDirection directionOf(WidgetTester tester) =>
      tester.widget<Directionality>(find.byType(Directionality).first)
          .textDirection;

  /// An order whose receipt carries BOTH snapshots — the scenario every
  /// seeded order and every placed order has (Task 23 follow-up).
  Order bilingualOrder() => Order(
        id: 1,
        orderNumber: 'ORD-000004',
        status: OrderStatus.pending,
        subtotalCents: 5900,
        discountCents: 0,
        totalCents: 5900,
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
            quantity: 1,
          ),
        ],
        statusHistory: [
          OrderStatusEntry(
            status: OrderStatus.pending,
            changedAt: DateTime(2026, 7, 1, 6),
          ),
        ],
        createdAt: DateTime(2026, 7, 1, 6),
        updatedAt: DateTime(2026, 7, 1, 6),
      );

  Widget receiptApp(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OrderDetailView(order: bilingualOrder()),
        ),
      );

  testWidgets('a receipt renders in the VIEWER locale, not the orderer\'s',
      (WidgetTester tester) async {
    // Same stored order: Arabic viewer sees the Arabic snapshot...
    await tester.pumpWidget(receiptApp(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('سجادة يوجا'), findsOneWidget);

    // ...and an English viewer sees the English snapshot.
    await tester.pumpWidget(receiptApp(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Yoga Mat'), findsOneWidget);
  });

  testWidgets('boots in English, LTR, with the shop shell',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Shop'), findsWidgets); // nav label + screen title
    expect(directionOf(tester), TextDirection.ltr);

    await unmountApp(tester);
  });

  testWidgets('switching to Arabic localizes strings and flips to RTL',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await getIt<LocaleCubit>().setLocaleCode('ar');
    await tester.pumpAndSettle();

    expect(find.text('المتجر'), findsWidgets); // Shop tab + title
    expect(directionOf(tester), TextDirection.rtl);

    // Seed *content* switches with the locale too (Task 23 follow-up): the
    // category chip and the first card (name tiebreak sorts alphabetically,
    // so 'Cast Iron Pan' is the top-left product) render Arabic while the
    // canonical English stays stored in the DB.
    expect(find.text('ملابس'), findsWidgets); // Clothing category
    expect(find.text('مقلاة من حديد الزهر'), findsOneWidget);

    // Switching back restores English immediately (no restart needed).
    await getIt<LocaleCubit>().setLocaleCode('en');
    await tester.pumpAndSettle();

    expect(find.text('Shop'), findsWidgets);
    expect(find.text('Cast Iron Pan'), findsOneWidget);
    expect(directionOf(tester), TextDirection.ltr);

    await unmountApp(tester);
  });
}

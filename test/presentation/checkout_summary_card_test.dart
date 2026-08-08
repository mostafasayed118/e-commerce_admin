import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/domain/repositories/cart_repository.dart';
import 'package:shop_admin/domain/repositories/category_repository.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/checkout/widgets/checkout_summary_card.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// Pumps the summary card under the app's localization delegates (it reads
/// `context.l10n` / `context.formatCents`). The card derives its totals from
/// the DI-owned [CartCubit] — the same direct-bloc pattern as the real
/// checkout route — so the cart is seeded through the repositories first.
Future<void> pumpCard(
  WidgetTester tester, {
  String? couponCode,
  int couponDiscountCents = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CheckoutSummaryCard(
        couponCode: couponCode,
        couponDiscountCents: couponDiscountCents,
      )),
    ),
  );
  await settleDrift(tester); // CartCubit's watch streams → CartLoaded
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  testWidgets('an empty cart renders zero totals without savings rows',
      (WidgetTester tester) async {
    await pumpCard(tester);

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(r'$0.00'), findsNWidgets(2)); // subtotal + total
    // No savings or coupon rows when there is nothing to save.
    expect(find.text('Savings'), findsNothing);
    expect(find.textContaining('Coupon'), findsNothing);

    await unmountApp(tester); // flush the cubit's drift-cleanup timers
  });

  testWidgets('seeded cart shows subtotal, savings, and total',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      await getIt<CategoryRepository>().createCategory(
        const Category(id: 1, name: 'Clothing'),
      );
      final product = await getIt<ProductRepository>().createProduct(
        const Product(
          id: 1,
          categoryId: 1,
          name: 'Classic Tee',
          priceCents: 2000,
          discountPercent: 25,
          stock: 10,
        ),
      );
      await getIt<CartRepository>().setQuantity(product.getOrThrow().id, 2);
    });

    await pumpCard(tester);

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(r'$40.00'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text(r'-$10.00'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(r'$30.00'), findsOneWidget);

    await unmountApp(tester); // flush the cubit's drift-cleanup timers
  });

  testWidgets('an applied coupon line reduces the total',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      await getIt<CategoryRepository>().createCategory(
        const Category(id: 1, name: 'Clothing'),
      );
      final product = await getIt<ProductRepository>().createProduct(
        const Product(
          id: 1,
          categoryId: 1,
          name: 'Classic Tee',
          priceCents: 2000,
          discountPercent: 25,
          stock: 10,
        ),
      );
      await getIt<CartRepository>().setQuantity(product.getOrThrow().id, 2);
    });

    await pumpCard(tester, couponCode: 'SAVE10', couponDiscountCents: 500);

    // Coupon row: "Coupon (SAVE10)" at -$5.00; total drops to $25.00.
    expect(find.text('Coupon (SAVE10)'), findsOneWidget);
    expect(find.text(r'-$5.00'), findsOneWidget);
    expect(find.text(r'$25.00'), findsOneWidget);

    await unmountApp(tester); // flush the cubit's drift-cleanup timers
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/wishlist/widgets/wishlist_heart.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// Pumps the heart with the app's localization delegates (it reads
/// `context.l10n` for tooltips and SnackBars). Seeding runs first — the
/// toggle inserts a wishlist row with an FK to products, so an empty DB
/// would reject the write and the heart would never fill. The FK needs a
/// product with the passed id to exist (id 1 — the seed's first product,
/// 'Classic Tee'); a future seed reorder fails loudly here, not silently.
Future<void> pumpHeart(
  WidgetTester tester,
  Product product, {
  Locale? locale,
}) async {
  await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: WishlistHeartButton(product: product)),
    ),
  );
  await settleDrift(tester);
}

Product tee() =>
    const Product(id: 1, categoryId: 1, name: 'Classic Tee', priceCents: 2000, stock: 10);

/// Taps the heart in whatever state it currently is (tooltip flips with it).
Future<void> tapHeart(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  // Real DI write + the wishlist stream round-trip need a real-async window.
  await settleAction(tester, delay: const Duration(milliseconds: 200));
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

  testWidgets('an unsaved product shows the outline heart and add tooltip',
      (WidgetTester tester) async {
    await pumpHeart(tester, tee());

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byTooltip('Add to wishlist'), findsOneWidget);
    expect(find.byTooltip('Remove from wishlist'), findsNothing);

    // Uniform tail: the render-only test has no pending timers today, but
    // unmounting keeps the trio consistent if it ever grows a mutation.
    await unmountApp(tester);
  });

  testWidgets('tapping saves the product, fills the heart, and toasts',
      (WidgetTester tester) async {
    await pumpHeart(tester, tee());

    await tapHeart(tester, 'Add to wishlist');

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.byTooltip('Remove from wishlist'), findsOneWidget);
    expect(find.text('Classic Tee added to wishlist'), findsOneWidget);

    await settleSnackBar(tester);
    await unmountApp(tester);
  });

  testWidgets('tapping again removes the product and unfills the heart',
      (WidgetTester tester) async {
    await pumpHeart(tester, tee());

    await tapHeart(tester, 'Add to wishlist');
    await settleSnackBar(tester);

    await tapHeart(tester, 'Remove from wishlist');

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.text('Classic Tee removed from wishlist'), findsOneWidget);

    await settleSnackBar(tester);
    await unmountApp(tester);
  });

  testWidgets('Arabic renders the tooltip and toast in Arabic',
      (WidgetTester tester) async {
    await pumpHeart(tester, tee(), locale: const Locale('ar'));

    expect(find.byTooltip('أضف إلى المفضلة'), findsOneWidget);

    await tapHeart(tester, 'أضف إلى المفضلة');

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.textContaining('تمت إضافة'), findsOneWidget);

    await settleSnackBar(tester);
    await unmountApp(tester);
  });
}

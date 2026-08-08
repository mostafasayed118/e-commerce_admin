import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';

import '../helpers/drift_settle.dart';
import '../helpers/nav.dart';
import '../helpers/shop_flow.dart';
import '../helpers/test_di.dart';

/// End-to-end wishlist: real DI graph (memory DB + seed) + the real router.
/// Hearts on the catalog cards and the product detail screen toggle
/// membership; the shell badge and the wishlist screen stay live; move-to-cart
/// reuses the existing AddToCart rules (out-of-stock is rejected).
void main() {
  late AppDatabase db;
  late GoRouter router;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    router.dispose();
    await db.close();
    await getIt.reset();
  });

  testWidgets(
      'card heart saves a product, the badge + wishlist screen stay live, '
      'and move-to-cart lands it in the cart', (WidgetTester tester) async {
    router = await pumpRouterApp(tester);

    // 'Cast Iron Pan' is the alphabetically-first product (top-left card),
    // so its heart is the first "Add to wishlist" tooltip in the tree.
    await tester.tap(find.byTooltip('Add to wishlist').first);
    await settleAction(tester);

    // The wishlist really persisted.
    final savedRows = await (db.select(db.wishlistItems)).get();
    expect(savedRows, hasLength(1));

    // The shell badge on the Wishlist tab shows the live count.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );

    await settleSnackBar(tester);

    await goToDestinationByLabel(tester, 'Wishlist');

    expect(find.text('Cast Iron Pan'), findsOneWidget);

    // Move to cart: the item leaves the wishlist and lands in the cart.
    // Two settles: the first lets AddToCart's chain complete (its stream
    // read starts on the tap-time pump, delivered by the runAsync window);
    // the second lets the follow-up wishlist-toggle chain complete (it only
    // starts mid-runAsync, so its drift query is scheduled at the trailing
    // pump and needs one more real-async window to land).
    await tester.tap(find.text('Move to cart'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 300));
    await settleDrift(tester, delay: const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('Your wishlist is empty'), findsOneWidget);
    final cartRows = await (db.select(db.cartItems)).get();
    expect(cartRows, hasLength(1));
    expect(cartRows.single.quantity, 1);

    // The cart badge picked the item up too.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );

    await settleSnackBar(tester);
    await unmountApp(tester);
  });

  testWidgets(
      "'Add all to cart' moves every in-stock item and leaves unavailable "
      'ones wishlisted, reporting the split', (WidgetTester tester) async {
    router = await pumpRouterApp(tester);

    // Save one in-stock item (Cast Iron Pan — the alphabetically-first card)
    // and the out-of-stock Leather Belt (via search, like the other test).
    await tester.tap(find.byTooltip('Add to wishlist').first);
    await settleAction(tester);
    await settleSnackBar(tester);

    await tester.enterText(find.byType(TextField), 'belt');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Leather Belt'));
    await settleAction(tester);
    await tester.tap(find.byTooltip('Add to wishlist'));
    await settleAction(tester, delay: const Duration(milliseconds: 200));
    await settleSnackBar(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await goToDestinationByLabel(tester, 'Wishlist');

    expect(find.text('Cast Iron Pan'), findsOneWidget);
    expect(find.text('Leather Belt'), findsOneWidget);

    // One tap: the in-stock item moves, the out-of-stock one stays saved.
    // The bulk runs two sequential move chains (each: product read → cart
    // read → write → wishlist removal), so it needs wider settle windows
    // than the single-move test.
    await tester.tap(find.text('Add all to cart'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 400));
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Added 1 to cart · 1 unavailable'), findsOneWidget);
    expect(find.text('Cast Iron Pan'), findsNothing); // moved out of wishlist
    expect(find.text('Leather Belt'), findsOneWidget); // still saved

    // DB proof: the in-stock item is in the cart at qty 1; only the
    // out-of-stock item remains wishlisted.
    final pan = await (db.select(db.products)
          ..where((t) => t.name.equals('Cast Iron Pan')))
        .getSingle();
    final cartRows = await (db.select(db.cartItems)).get();
    expect(cartRows, hasLength(1));
    expect(cartRows.single.productId, pan.id);
    expect(cartRows.single.quantity, 1);

    final wishlistRows = await (db.select(db.wishlistItems)).get();
    expect(wishlistRows, hasLength(1));
    final belt = await (db.select(db.products)
          ..where((t) => t.name.equals('Leather Belt')))
        .getSingle();
    expect(wishlistRows.single.productId, belt.id);

    await settleSnackBar(tester);
    await unmountApp(tester);
  });

  testWidgets("'Add all to cart' with only in-stock items moves everything",
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester);

    // Save the in-stock Cast Iron Pan only.
    await tester.tap(find.byTooltip('Add to wishlist').first);
    await settleAction(tester);
    await settleSnackBar(tester);
    await goToDestinationByLabel(tester, 'Wishlist');

    expect(find.text('Cast Iron Pan'), findsOneWidget);

    await tester.tap(find.text('Add all to cart'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 400));
    await settleDrift(tester, delay: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // The all-added success message (singular plural form).
    expect(find.text('Added 1 item to cart'), findsOneWidget);
    expect(find.text('Your wishlist is empty'), findsOneWidget);

    final cartRows = await (db.select(db.cartItems)).get();
    expect(cartRows, hasLength(1));
    expect(cartRows.single.quantity, 1);
    expect(await (db.select(db.wishlistItems)).get(), isEmpty);

    await settleSnackBar(tester);
    await unmountApp(tester);
  });

  testWidgets("'Add all to cart' with only unavailable items adds nothing",
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester);

    // Save only the out-of-stock Leather Belt (via search).
    await tester.enterText(find.byType(TextField), 'belt');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Leather Belt'));
    await settleAction(tester);
    await tester.tap(find.byTooltip('Add to wishlist'));
    await settleAction(tester, delay: const Duration(milliseconds: 200));
    await settleSnackBar(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await goToDestinationByLabel(tester, 'Wishlist');

    await tester.tap(find.text('Add all to cart'));
    await tester.pump();
    await settleDrift(tester, delay: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Nothing was added — unavailable items stay in your wishlist.',
      ),
      findsOneWidget,
    );
    expect(find.text('Leather Belt'), findsOneWidget); // still saved
    expect(await (db.select(db.cartItems)).get(), isEmpty);
    expect(await (db.select(db.wishlistItems)).get(), hasLength(1));

    await settleSnackBar(tester);
    await unmountApp(tester);
  });

  testWidgets(
      'the detail heart toggles a product and out-of-stock items cannot '
      'move to cart', (WidgetTester tester) async {
    router = await pumpRouterApp(tester);

    // Narrow the catalog with search, then open the out-of-stock Leather
    // Belt (avoids grid scrolling; the search field is the one on the
    // catalog header).
    await tester.enterText(find.byType(TextField), 'belt');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Leather Belt'));
    await settleAction(tester);

    await tester.tap(find.byTooltip('Add to wishlist'));
    await settleAction(tester, delay: const Duration(milliseconds: 200));

    // The heart fills — feedback that the product is now saved.
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await settleSnackBar(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await goToDestinationByLabel(tester, 'Wishlist');

    expect(find.text('Leather Belt'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);

    // Move-to-cart must refuse via AddToCart's out-of-stock rule.
    await tester.tap(find.text('Move to cart'));
    await settleAction(tester, delay: const Duration(milliseconds: 300));

    expect(find.text('Leather Belt is out of stock.'), findsOneWidget);
    expect(find.text('Leather Belt'), findsOneWidget); // still saved

    await settleSnackBar(tester);
    await unmountApp(tester);
  });
}

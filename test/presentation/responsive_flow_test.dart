import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/product_image.dart';
import 'package:shop_admin/presentation/features/checkout/widgets/checkout_summary_card.dart';
import 'package:shop_admin/presentation/widgets/responsive/content_max_width.dart';
import 'package:shop_admin/presentation/widgets/responsive/responsive_breakpoints.dart';

import '../helpers/drift_settle.dart';
import '../helpers/nav.dart';
import '../helpers/shop_flow.dart';
import '../helpers/test_di.dart';

/// End-to-end responsive checks on the real router: the same screens render
/// side-by-side on wide surfaces and stacked on phones, and page content is
/// capped (not stretched) on very wide windows.
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

  Future<void> openClassicTee(WidgetTester tester) async {
    await tester.tap(find.text('Classic Tee'));
    await settleAction(tester); // detail watchProductById stream
  }

  Future<void> openCheckout(WidgetTester tester) async {
    await addClassicTee(tester);
    await goToDestinationByLabel(tester, 'Cart');
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
  }

  testWidgets('wide surface: product detail splits image | info',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(1600, 1000));
    await openClassicTee(tester);

    // Two-pane: the image and the product name share the top edge, with the
    // name to the right of the image.
    final image = tester.getTopLeft(find.byType(ProductImage));
    final name = tester.getTopLeft(find.text('Classic Tee'));
    expect((image.dy - name.dy).abs(), lessThan(2));
    expect(name.dx, greaterThan(image.dx + 100));

    await unmountApp(tester);
  });

  testWidgets('phone surface: product detail stacks image above info',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester); // 390x844 default
    await openClassicTee(tester);

    final image = tester.getTopLeft(find.byType(ProductImage));
    final name = tester.getTopLeft(find.text('Classic Tee'));
    // Stacked: the name sits below the image and shares its column.
    expect(name.dy, greaterThan(image.dy + 100));
    expect((name.dx - image.dx).abs(), lessThan(60));

    await unmountApp(tester);
  });

  testWidgets('wide surface: checkout splits form | summary',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(1600, 1000));
    await openCheckout(tester);

    // Two-pane: the shipping form and the summary card sit side by side.
    final nameField =
        tester.getTopLeft(find.byKey(const Key('checkout-name')));
    final summary = tester.getTopLeft(find.byType(CheckoutSummaryCard));
    expect(summary.dx, greaterThan(nameField.dx + 100));
    expect((summary.dy - nameField.dy).abs(), lessThan(80));

    await unmountApp(tester);
  });

  testWidgets('phone surface: checkout stacks form above summary',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(420, 1600));
    await openCheckout(tester);

    // Stacked: the summary card sits below the shipping form in one column.
    final nameField =
        tester.getTopLeft(find.byKey(const Key('checkout-name')));
    final summary = tester.getTopLeft(find.byType(CheckoutSummaryCard));
    expect(summary.dy, greaterThan(nameField.dy + 100));
    expect((summary.dx - nameField.dx).abs(), lessThan(60));

    await unmountApp(tester);
  });

  testWidgets('very wide window: page content is capped and centered',
      (WidgetTester tester) async {
    router = await pumpRouterApp(tester, size: const Size(2400, 1000));

    // The catalog grid lives inside the capped ContentMaxWidth — its width
    // is the capped width, not the full 2400 surface. (The ContentMaxWidth
    // widget's own render box is the full-width Align wrapper, which spans
    // the body — the rail offsets it from the surface, so centering is
    // asserted against that wrapper rather than the surface.)
    final grid = tester.renderObject<RenderBox>(find.byType(GridView));
    expect(grid.size.width, ResponsiveBreakpoints.contentMaxWidth);
    final wrapper =
        tester.renderObject<RenderBox>(find.byType(ContentMaxWidth));
    // Centered: the grid's center aligns with the wrapper's center (equal
    // gutters on both sides regardless of the rail's offset).
    expect(
      grid.localToGlobal(Offset.zero).dx + grid.size.width / 2,
      closeTo(
        wrapper.localToGlobal(Offset.zero).dx + wrapper.size.width / 2,
        0.1,
      ),
    );

    await unmountApp(tester);
  });
}

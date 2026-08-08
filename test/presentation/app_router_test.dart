import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/presentation/features/admin/catalog/products_screen.dart';
import 'package:shop_admin/presentation/features/cart/cart_screen.dart';
import 'package:shop_admin/presentation/features/admin/gate/admin_gate_screen.dart';
import 'package:shop_admin/presentation/router/admin_session.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

import '../helpers/drift_settle.dart';
import '../helpers/storefront_exit.dart';
import '../helpers/test_app.dart';
import '../helpers/test_di.dart';

void main() {
  late AppDatabase db;
  late GoRouter router;

  setUp(() {
    db = setupTestDi();
    router = buildAppRouter();
  });

  tearDown(() async {
    router.dispose();
    await db.close();
    await getIt.reset();
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    // Deliberately not pumpRouterApp: the router is built in setUp (this
    // file tests the guard itself) and pumped on the default test surface —
    // pumpRouterApp would impose a phone surface and replace the setUp
    // router, orphaning it from tearDown's dispose.
    // Seed so the storefront-exit assertion can anchor on the catalog's
    // headline product (the flow tests' full-app pumps seed too).
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    await tester.pumpWidget(testApp(router));
    // Initial route is the catalog (drift-backed) — settle the streams.
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  Future<String> currentPath(WidgetTester tester) async {
    // The gate screen queries isPinSet on build (drift) — settle before
    // asserting, and settle animations.
    await settleDrift(tester);
    await tester.pumpAndSettle();
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  group('admin route guard', () {
    testWidgets('redirects every admin route to the gate while locked',
        (WidgetTester tester) async {
      await pumpRouter(tester);

      router.go('/admin/overview');
      expect(await currentPath(tester), '/admin/gate');
      expect(find.byType(AdminGateScreen), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('lets admin routes through once the session is unlocked',
        (WidgetTester tester) async {
      getIt<AdminSession>().unlocked = true;
      await pumpRouter(tester);

      router.go('/admin/products');
      expect(await currentPath(tester), '/admin/products');
      expect(find.byType(ProductsScreen), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('the gate itself is always reachable, even while locked',
        (WidgetTester tester) async {
      await pumpRouter(tester);

      router.go('/admin/gate');
      expect(await currentPath(tester), '/admin/gate');
      expect(find.byType(AdminGateScreen), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('the gate storefront exit returns to the customer view',
        (WidgetTester tester) async {
      await pumpRouter(tester);

      // Land on the gate while locked, back out through its storefront
      // action, and verify we're on the shop root — not stuck in admin.
      router.go('/admin/gate');
      expect(await currentPath(tester), '/admin/gate');

      // The shared verification: tap → settle → the catalog is showing
      // (the catalog only renders on '/', so the content assert is the
      // route proof).
      await tapStorefrontExitToStore(tester);

      await unmountApp(tester);
    });

    testWidgets('a fresh session starts locked', (WidgetTester tester) async {
      expect(getIt<AdminSession>().unlocked, isFalse);
    });
  });

  group('shop routes', () {
    testWidgets('are never gated', (WidgetTester tester) async {
      await pumpRouter(tester);

      router.go('/cart');
      expect(await currentPath(tester), '/cart');
      expect(find.byType(CartScreen), findsOneWidget);

      await unmountApp(tester);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/features/admin/gate/admin_gate_screen.dart';
import 'package:shop_admin/presentation/router/admin_session.dart';
import 'package:shop_admin/presentation/router/app_router.dart';

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
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<String> currentPath(WidgetTester tester) async {
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
    });

    testWidgets('lets admin routes through once the session is unlocked',
        (WidgetTester tester) async {
      getIt<AdminSession>().unlocked = true;
      await pumpRouter(tester);

      router.go('/admin/products');
      expect(await currentPath(tester), '/admin/products');
      expect(find.text('This screen arrives in Task 14.'), findsOneWidget);
    });

    testWidgets('the gate itself is always reachable, even while locked',
        (WidgetTester tester) async {
      await pumpRouter(tester);

      router.go('/admin/gate');
      expect(await currentPath(tester), '/admin/gate');
      expect(find.byType(AdminGateScreen), findsOneWidget);
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
      expect(find.text('This screen arrives in Task 15.'), findsOneWidget);
    });
  });
}

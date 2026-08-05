import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/app.dart';
import 'package:shop_admin/presentation/shells/shell_scaffold.dart';

import 'helpers/test_di.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  testWidgets('boots into the shop shell and navigates branches',
      (WidgetTester tester) async {
    // Narrow phone-like viewport -> the constraint-based layout picks the
    // bottom NavigationBar (800x600 default would pick the rail instead).
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ShopAdminApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Shop'), findsWidgets); // nav label + placeholder title

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('This screen arrives in Task 15.'), findsOneWidget);
  });

  testWidgets('switches to the rail layout on wide viewports',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ShopAdminApp());
    await tester.pumpAndSettle();

    // The 720px breakpoint: wide means NavigationRail, no bottom bar.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(ShellScaffold.wideBreakpoint, 720);
  });
}

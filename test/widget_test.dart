import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/app.dart';
import 'package:shop_admin/presentation/shells/shell_scaffold.dart';
import 'package:shop_admin/presentation/theme/theme_cubit.dart';

import 'helpers/drift_settle.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ShopAdminApp());
    // The catalog cubit subscribes to drift watch streams on startup; give
    // the background isolate a chance to deliver (FakeAsync cannot see it).
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('boots into the shop shell and navigates branches',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Narrow viewport -> the constraint-based layout picks the bottom bar.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Shop'), findsWidgets); // nav label + screen title

    await tester.tap(find.text('Cart'));
    await tester.pump();
    await settleDrift(tester); // CartCubit watch streams
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('the root wires the ThemeCubit choice into MaterialApp',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    // A persisted choice flows to the MaterialApp (light/dark switching is
    // driven by this single cubit everywhere).
    await getIt<ThemeCubit>().setThemeMode(ThemeMode.dark);
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await unmountApp(tester);
  });

  testWidgets('switches to the rail layout on wide viewports',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ShopAdminApp());
    await settleDrift(tester);
    await tester.pumpAndSettle();

    // The 720px breakpoint: wide means NavigationRail, no bottom bar.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(ShellScaffold.wideBreakpoint, 720);

    await unmountApp(tester);
  });
}

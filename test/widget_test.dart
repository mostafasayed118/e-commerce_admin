import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/shells/shell_scaffold.dart';
import 'package:shop_admin/presentation/theme/theme_cubit.dart';

import 'helpers/drift_settle.dart';
import 'helpers/shop_flow.dart';
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
    // Fresh install: no seed — the boot tests assert the empty states.
    await pumpFullApp(tester, seed: false);
  }

  testWidgets('boots into the shop shell and navigates branches',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Narrow viewport -> the constraint-based layout picks the bottom bar.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Shop'), findsWidgets); // nav label + screen title

    await tester.tap(find.text('Cart'));
    await settleAction(tester); // CartCubit watch streams
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
    // Fresh install on a wide surface (no seed — layout-only asserts).
    await pumpFullApp(tester, size: const Size(1200, 800), seed: false);

    // The 720px breakpoint: wide means NavigationRail, no bottom bar.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(ShellScaffold.wideBreakpoint, 720);

    await unmountApp(tester);
  });
}

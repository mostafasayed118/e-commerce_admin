import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/profile/widgets/profile_settings_section.dart';
import 'package:shop_admin/presentation/locale/locale_cubit.dart';
import 'package:shop_admin/presentation/theme/theme_cubit.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// Pumps the settings section inside a small GoRouter (it navigates with
/// `context.push` to the admin gate) under the app's localization delegates.
/// The two settings Cubits are DI singletons (ThemeCubit/LocaleCubit), so the
/// real composition root must be up first — same as profile_flow_test.
Future<void> pumpSection(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  // The cubits restore their persisted values on first access (UiPrefs read).
  await settleDrift(tester);
  await tester.pumpAndSettle();
}

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

  GoRouter buildRouter() => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: ProfileSettingsSection()),
          ),
          GoRoute(
            path: '/admin/gate',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('gate sentinel'))),
          ),
        ],
      );

  testWidgets('renders the preferences block with both switch groups',
      (WidgetTester tester) async {
    router = buildRouter();
    await pumpSection(tester, router: router);

    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    // Theme modes + language names (each shown in its OWN name).
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    // The admin entry.
    expect(find.text('Admin dashboard'), findsOneWidget);
    expect(find.text('PIN-protected shop management'), findsOneWidget);

    await unmountApp(tester); // flush the cubits' drift-cleanup timers
  });

  testWidgets('the Appearance switch updates the persisted ThemeCubit',
      (WidgetTester tester) async {
    router = buildRouter();
    await pumpSection(tester, router: router);

    expect(getIt<ThemeCubit>().state, ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    await settleDrift(tester); // ThemeCubit persistence write
    await tester.pumpAndSettle();

    expect(getIt<ThemeCubit>().state, ThemeMode.dark);

    await unmountApp(tester); // flush the cubits' drift-cleanup timers
  });

  testWidgets('the Language switch updates the persisted LocaleCubit',
      (WidgetTester tester) async {
    router = buildRouter();
    await pumpSection(tester, router: router);

    expect(getIt<LocaleCubit>().state, const Locale('en'));

    await tester.tap(find.text('العربية'));
    await tester.pump();
    await settleDrift(tester); // LocaleCubit persistence write
    await tester.pumpAndSettle();

    expect(getIt<LocaleCubit>().state, const Locale('ar'));

    await unmountApp(tester); // flush the cubits' drift-cleanup timers
  });

  testWidgets('the Admin entry pushes the PIN gate route',
      (WidgetTester tester) async {
    router = buildRouter();
    await pumpSection(tester, router: router);

    await tester.tap(find.text('Admin dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('gate sentinel'), findsOneWidget);

    await unmountApp(tester); // flush the cubits' drift-cleanup timers
  });
}

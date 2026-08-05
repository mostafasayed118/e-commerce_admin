import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/presentation/features/admin/gate/admin_gate_screen.dart';
import 'package:shop_admin/presentation/router/app_router.dart';
import 'package:shop_admin/presentation/theme/theme_cubit.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// End-to-end customer profile: real DI graph + router. The profile is the
/// same single-row [ShippingInfo] the checkout writes (PlaceOrder), so these
/// tests also prove the reactive re-seed across writers.
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    router = buildAppRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await settleDrift(tester);
    await tester.pumpAndSettle();
  }

  Future<void> goToProfile(WidgetTester tester) async {
    router.go('/profile');
    await tester.pump();
    await settleDrift(tester); // ProfileCubit watch stream
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String key) {
    final field = tester.widget<TextFormField>(find.byKey(Key(key)));
    return field.controller!.text;
  }

  testWidgets('an empty profile is a blank form; saving persists and confirms',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToProfile(tester);

    // Fresh install: blank form + the hint.
    expect(find.textContaining('No saved details yet'), findsOneWidget);
    expect(fieldText(tester, 'profile-name'), isEmpty);

    await tester.enterText(find.byKey(const Key('profile-name')), 'Ada Lovelace');
    await tester.enterText(find.byKey(const Key('profile-phone')), '555-0100');
    await tester.enterText(
      find.byKey(const Key('profile-address')),
      '1 Analytical Way',
    );
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pump();
    await settleDrift(tester); // SaveProfile → drift write → stream re-emit
    await tester.pumpAndSettle();

    expect(find.text('Profile saved.'), findsOneWidget);

    // Persisted through the real repository (what checkout will pre-fill).
    final saved = await tester.runAsync(
      () => getIt<SettingsRepository>().getProfile(),
    );
    expect(saved?.getOrThrow(), const ShippingInfo(
      name: 'Ada Lovelace',
      phone: '555-0100',
      address: '1 Analytical Way',
    ));

    await unmountApp(tester);
  });

  testWidgets('a previously saved profile pre-fills the form',
      (WidgetTester tester) async {
    // Write the profile through the data layer first — the same path
    // checkout takes when the customer places an order.
    await tester.runAsync(
      () => getIt<SettingsRepository>().updateProfile(
        const ShippingInfo(name: 'Grace Hopper', phone: '555-0200', address: '2 COBOL Ave'),
      ),
    );

    await pumpApp(tester);
    await goToProfile(tester);

    expect(fieldText(tester, 'profile-name'), 'Grace Hopper');
    expect(fieldText(tester, 'profile-phone'), '555-0200');
    expect(fieldText(tester, 'profile-address'), '2 COBOL Ave');
    expect(find.textContaining('No saved details yet'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('an external save re-seeds a pristine form but never clobbers edits',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToProfile(tester);

    // A checkout (elsewhere) saves a profile while we sit on the tab: the
    // pristine form picks it up automatically.
    await tester.runAsync(
      () => getIt<SettingsRepository>().updateProfile(
        const ShippingInfo(name: 'Grace Hopper'),
      ),
    );
    await settleDrift(tester);
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'profile-name'), 'Grace Hopper');

    // Now the user starts typing; a second external save must NOT clobber.
    await tester.enterText(
      find.byKey(const Key('profile-name')),
      'Partially typed…',
    );
    await tester.runAsync(
      () => getIt<SettingsRepository>().updateProfile(
        const ShippingInfo(name: 'Katherine Johnson'),
      ),
    );
    await settleDrift(tester);
    await tester.pumpAndSettle();
    expect(fieldText(tester, 'profile-name'), 'Partially typed…');

    await unmountApp(tester);
  });

  testWidgets('the Appearance switch applies and persists the theme',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToProfile(tester);

    // Default: follows the OS (the DI singleton's initial state).
    expect(getIt<ThemeCubit>().state, ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    await settleDrift(tester); // ThemeCubit persistence write
    await tester.pumpAndSettle();

    // Applied immediately to the DI singleton that drives the real app's
    // MaterialApp (root wiring is asserted in widget_test, which pumps
    // ShopAdminApp)…
    expect(getIt<ThemeCubit>().state, ThemeMode.dark);
    // …and persisted to the UiPrefs row (survives restarts).
    final prefs = await tester.runAsync(
      () => getIt<SettingsRepository>().getUiPrefs(),
    );
    expect(prefs?.getOrThrow().themeModeCode, 'dark');

    await unmountApp(tester);
  });

  testWidgets('the Admin entry on the profile tab reaches the locked gate',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToProfile(tester);

    // The one on-screen path to the admin area (everything else is deep
    // links behind the redirect guard). The Preferences section sits above
    // it, so scroll it into the 844px viewport first. Fresh DB → the gate
    // asks to set a PIN.
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-admin-entry')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('profile-admin-entry')));
    await tester.pump();
    await settleDrift(tester); // gate's isPinSet() query
    await tester.pumpAndSettle();

    expect(find.byType(AdminGateScreen), findsOneWidget);
    expect(find.text('Set an admin PIN'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('saving an empty form shows the shared inline validation errors',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await goToProfile(tester);

    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pump();
    await settleDrift(tester);
    await tester.pumpAndSettle();

    // The same validateShipping rules checkout uses (one source of truth).
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    expect(find.text('Address is required'), findsOneWidget);
    // And nothing was persisted.
    final saved = await tester.runAsync(
      () => getIt<SettingsRepository>().getProfile(),
    );
    expect(saved?.getOrNull(), isNull);

    await unmountApp(tester);
  });
}

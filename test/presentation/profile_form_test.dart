import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/domain/repositories/settings_repository.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/profile/profile_cubit.dart';
import 'package:shop_admin/presentation/features/profile/widgets/profile_form.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// Pumps [ProfileForm] with a fixed [state] — for render-only tests (prefill,
/// hints, saving/saved/error branches). The DI-owned cubit is provided (the
/// form reads it on save) but the widget is NOT rebuilt from the cubit's
/// stream, so the passed state is what renders. Uses timed pumps, never
/// pumpAndSettle: the saving state's spinner animates forever.
Future<GoRouter> pumpFormWithState(
  WidgetTester tester, {
  required ProfileLoaded state,
  Locale? locale,
}) async {
  final router = await _pump(
    tester,
    locale: locale,
    builder: (context, routeState) => BlocProvider<ProfileCubit>.value(
      value: getIt<ProfileCubit>(),
      // The real screen renders the form inside a Scaffold (the form's
      // fields need a Material ancestor).
      child: Scaffold(body: ProfileForm(state: state)),
    ),
  );
  await settleDrift(tester); // Theme/Locale cubits restore from UiPrefs
  await tester.pump(const Duration(milliseconds: 100));
  return router;
}

/// Pumps the profile tab the way the real screen does — a BlocBuilder over
/// the DI-owned cubit switching to [ProfileForm] when loaded — so a save
/// through the cubit re-renders the form with the just-saved state.
Future<GoRouter> pumpLiveForm(WidgetTester tester, {Locale? locale}) async {
  final router = await _pump(
    tester,
    locale: locale,
    builder: (context, routeState) => BlocProvider<ProfileCubit>.value(
      value: getIt<ProfileCubit>(),
      child: Scaffold(
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) => switch (state) {
            ProfileLoaded() => ProfileForm(state: state),
            _ => const SizedBox(),
          },
        ),
      ),
    ),
  );
  await settleDrift(tester); // watch stream → ProfileLoaded + UiPrefs restore
  await tester.pumpAndSettle();
  return router;
}

/// The shared pump tail: surface, router, and app delegates.
Future<GoRouter> _pump(
  WidgetTester tester, {
  required Locale? locale,
  required Widget Function(BuildContext context, Object? routeState) builder,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: builder),
      GoRoute(
        path: '/admin/gate',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('gate sentinel'))),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
  return router;
}

ProfileLoaded loaded({
  ShippingInfo profile = const ShippingInfo(),
  bool saving = false,
  bool justSaved = false,
  AppErrorCode? saveErrorCode,
}) =>
    ProfileLoaded(
      profile: profile,
      saving: saving,
      saveError: null,
      saveErrorCode: saveErrorCode,
      justSaved: justSaved,
    );

void main() {
  late AppDatabase db;
  GoRouter? router;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    // Dispose on the failure path too (tearDown always runs) — a router
    // disposed only at a test's end would leak on a mid-test assertion. The
    // nullable field tolerates a test that fails before its pump assigns;
    // reset to null so the next test's tearDown can't double-dispose it.
    router?.dispose();
    router = null;
    await db.close();
    await getIt.reset();
  });

  testWidgets('a saved profile pre-fills the three fields',
      (WidgetTester tester) async {
    router = await pumpFormWithState(
      tester,
      state: loaded(
        profile: const ShippingInfo(
          name: 'Ada Lovelace',
          phone: '555-0100',
          address: '1 Analytical Way',
        ),
      ),
    );

    String fieldText(String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
    expect(fieldText('profile-name'), 'Ada Lovelace');
    expect(fieldText('profile-phone'), '555-0100');
    expect(fieldText('profile-address'), '1 Analytical Way');
    // A filled profile shows no fresh-install hint.
    expect(find.textContaining('No saved details yet'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('an empty profile shows the no-saved-details hint',
      (WidgetTester tester) async {
    router = await pumpFormWithState(tester, state: loaded());

    expect(find.textContaining('No saved details yet'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('an empty save shows the shared inline validation errors',
      (WidgetTester tester) async {
    router = await pumpFormWithState(tester, state: loaded());

    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pump();

    // The same validateShipping rules checkout uses (one source of truth).
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    expect(find.text('Address is required'), findsOneWidget);
    // Nothing persisted through the real repository.
    final saved = await tester.runAsync(
      () => getIt<SettingsRepository>().getProfile(),
    );
    expect(saved?.getOrNull(), isNull);

    await unmountApp(tester);
  });

  testWidgets('the saving state disables the button and shows a spinner',
      (WidgetTester tester) async {
    router = await pumpFormWithState(tester, state: loaded(saving: true));

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('profile-save')),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save profile'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('a just-saved state shows the confirmation line',
      (WidgetTester tester) async {
    router = await pumpFormWithState(tester, state: loaded(justSaved: true));

    expect(find.byKey(const Key('profile-saved')), findsOneWidget);
    expect(find.text('Profile saved.'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('a save error renders the localized message',
      (WidgetTester tester) async {
    router = await pumpFormWithState(
      tester,
      state: loaded(saveErrorCode: AppErrorCode.database),
    );

    expect(find.byKey(const Key('profile-error')), findsOneWidget);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );

    await unmountApp(tester);
  });

  testWidgets('a valid save persists and re-renders the just-saved state',
      (WidgetTester tester) async {
    // The live harness rebuilds the form from the cubit's stream, so the
    // just-saved confirmation appears without a manual state swap.
    router = await pumpLiveForm(tester);

    await tester.enterText(
      find.byKey(const Key('profile-name')),
      'Grace Hopper',
    );
    await tester.enterText(find.byKey(const Key('profile-phone')), '555-0200');
    await tester.enterText(
      find.byKey(const Key('profile-address')),
      '2 COBOL Ave',
    );
    await tester.tap(find.byKey(const Key('profile-save')));
    await settleAction(tester); // SaveProfile → drift write → stream re-emit

    expect(find.text('Profile saved.'), findsOneWidget);
    final saved = await tester.runAsync(
      () => getIt<SettingsRepository>().getProfile(),
    );
    expect(saved?.getOrThrow(), const ShippingInfo(
      name: 'Grace Hopper',
      phone: '555-0200',
      address: '2 COBOL Ave',
    ));

    await unmountApp(tester);
  });
}

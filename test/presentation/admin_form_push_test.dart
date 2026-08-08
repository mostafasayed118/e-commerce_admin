import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/locale/locale_cubit.dart';

import '../helpers/admin_flow.dart';
import '../helpers/drift_settle.dart';
import '../helpers/nav.dart';
import '../helpers/shop_flow.dart';
import '../helpers/storefront_exit.dart';
import '../helpers/test_di.dart';

/// Regression guard for the admin FAB hero-tag fix.
///
/// The admin shell keeps every *visited* branch alive (StatefulShellRoute's
/// IndexedStack), and the form routes live on the **root navigator**
/// (detail_routes.dart) so they cover the shell. Once two or more
/// FAB-bearing branches (Products / Categories / Coupons) are built, the
/// shell route's subtree holds several FloatingActionButtons at once. Before
/// the fix all three used the default hero tag, so any form push made the
/// root navigator's hero scan find multiple heroes with the same tag and
/// throw "multiple heroes share the same tag" (the digits sweep surfaced
/// this; the bare-router flow tests never did, because they build only one
/// FAB-bearing branch). Each admin FAB now carries a unique heroTag.
///
/// This test deliberately visits ALL three FAB-bearing branches first, so
/// every push below happens with three FABs in the tree — the exact
/// pre-fix crash condition. Popping back after each form proves the push
/// round-trips.
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
    // Wide: the NavigationRail layout (same surface as the digits sweep).
    await pumpFullApp(tester, size: const Size(900, 2200));
  }

  testWidgets('admin form pushes never collide on FAB hero tags '
      '(new/edit product, new/edit coupon)', (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester, setPinTitle: 'Set an admin PIN');

    // --- Build every FAB-bearing branch before any push --------------------
    // With Products + Coupons + Categories all alive, the shell subtree now
    // holds three FABs — the state that crashed on every push pre-fix.
    await goToDestinationByLabel(tester, 'Products');
    expect(find.text('Classic Tee'), findsOneWidget);

    await goToDestinationByLabel(tester, 'Coupons');
    expect(find.text('WELCOME10'), findsWidgets);

    // --- Categories: the FAB's dialog shares the collision surface ---------
    // showDialog defaults to useRootNavigator: true, so the dialog is pushed
    // on the ROOT navigator — where all three kept-alive FABs live. Pre-fix
    // this tap threw the identical hero collision; unique heroTags cover it.
    await goToDestinationByLabel(tester, 'Categories');
    expect(find.text('Clothing'), findsOneWidget);
    await tapAdminFab(tester);
    expect(find.text('New category'), findsWidgets); // dialog + FAB label
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Clothing'), findsOneWidget);

    // --- Products: create + edit -------------------------------------------
    await goToDestinationByLabel(tester, 'Products');
    await tapAdminFab(tester);
    // 'New product' is the form AppBar AND the branch FAB's label.
    expect(find.text('New product'), findsWidgets);
    await popAdminForm(tester);
    expect(find.text('Classic Tee'), findsOneWidget); // back on the list

    await tester.tap(find.text('Classic Tee')); // row → edit form
    await tester.pumpAndSettle();
    expect(find.text('Edit product'), findsOneWidget);
    // The pushed form carries its own storefront exit (the shell's is
    // covered beneath it).
    expectStorefrontAction(reason: 'edit-product form');
    await popAdminForm(tester);
    expect(find.text('Classic Tee'), findsOneWidget);

    // --- Coupons: create + edit (all three FABs still alive) ---------------
    await goToDestinationByLabel(tester, 'Coupons');
    await tapAdminFab(tester);
    expect(find.text('New coupon'), findsWidgets); // AppBar + FAB label
    expectStorefrontAction(reason: 'new-coupon form');
    await popAdminForm(tester);
    expect(find.text('WELCOME10'), findsWidgets);

    await tester.tap(find.text('WELCOME10').hitTestable()); // row → edit
    await tester.pumpAndSettle();
    expect(find.text('Edit coupon'), findsOneWidget);
    await popAdminForm(tester);
    expect(find.text('WELCOME10'), findsWidgets);

    await unmountApp(tester);
  });

  testWidgets('admin returns to the customer view and re-enters via the gate',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester, setPinTitle: 'Set an admin PIN');

    // --- Exit to the customer view ----------------------------------------
    // The shell-level affordance (rail trailing on this wide surface).
    expectStorefrontLabel(const Locale('en'));
    await tapStorefrontExitToStore(tester);

    // --- Re-enter: profile → admin entry → enter-PIN gate ------------------
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-admin-entry')));
    await settleAction(tester); // gate's isPinSet() query
    expect(find.text('Enter admin PIN'), findsOneWidget); // PIN already set

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Unlock'));
    await settleAction(tester, delay: const Duration(milliseconds: 200));
    expect(find.text('Overview'), findsWidgets); // admin overview again

    await unmountApp(tester);
  });

  testWidgets("a pushed admin form's storefront action jumps back to the shop",
      (WidgetTester tester) async {
    await pumpApp(tester);
    await unlockAdmin(tester, setPinTitle: 'Set an admin PIN');
    await goToDestinationByLabel(tester, 'Products');
    await tapAdminFab(tester);
    expect(find.text('New product'), findsWidgets);

    // The form's AppBar action — the shell-level exit is covered beneath.
    await tapStorefrontExitToStore(tester);

    await unmountApp(tester);
  });

  testWidgets('the storefront exit lands on the Arabic catalog',
      (WidgetTester tester) async {
    await pumpApp(tester);
    // Switch to Arabic up front (the full app listens to LocaleCubit), so
    // the exit navigation lands on the localized catalog — the ar branch of
    // the shared tapStorefrontExitToStore assertion.
    await getIt<LocaleCubit>().setLocaleCode('ar');
    await settleDrift(tester); // content re-reads in the new locale
    await tester.pumpAndSettle();

    // Unlock through the Arabic gate (the shared Profile walk with Arabic
    // labels — the digits sweep pins these strings).
    await unlockAdmin(
      tester,
      profileLabel: 'الملف الشخصي',
      setPinTitle: 'تعيين رمز PIN للإدارة',
      setPinLabel: 'تعيين الرمز',
      overviewLabel: 'نظرة عامة',
    );

    await goToDestinationByLabel(tester, 'المنتجات');
    await tapAdminFab(tester);

    // The form's AppBar action — lands on the Arabic catalog.
    await tapStorefrontExitToStore(tester, locale: const Locale('ar'));

    await unmountApp(tester);
  });
}

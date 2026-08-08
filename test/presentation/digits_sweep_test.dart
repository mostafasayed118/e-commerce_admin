import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/presentation/features/admin/overview/widgets/stat_card.dart';
import 'package:shop_admin/presentation/locale/locale_cubit.dart';

import '../helpers/admin_flow.dart';
import '../helpers/drift_settle.dart';
import '../helpers/shop_flow.dart';
import '../helpers/test_di.dart';

/// The digit-consistency sweep: renders every screen in Arabic and fails on
/// any Western digit in *display* text.
///
/// The app's numbers (prices, dates, counts, percentages, phones, form
/// hints) all render Eastern Arabic digits in the `ar` locale. The only
/// intentional Western digits are **identifiers** (order numbers, coupon
/// codes) and **editable input values** (prefilled form fields — what the
/// user typed or will edit). This test walks the whole app in Arabic and
/// enforces that contract: any other visible Western digit is a regression.
///
/// The exceptions are enumerated explicitly (not regex-swept away):
///  * identifiers embedded in localized prose — e.g. the receipt's coupon
///    row `القسيمة (WELCOME10)` keeps the code canonical;
///  * user-data shipping snapshots — seeded street addresses like
///    `14 Nile St, Cairo` are typed data, never reformatted (same as
///    phones).
class _Allowed {
  /// Identifiers that may appear as a whole text or inside localized prose
  /// (order numbers, coupon codes — optionally wrapped in parentheses).
  ///
  /// Deliberately permissive (`[A-Z]{2,}\d+`): the sweep's job is catching
  /// *unconverted display numbers*, which are usually standalone digits — an
  /// over-strip here would need a future English-named product with
  /// letter+digit clusters to sneak a Western digit through, an accepted
  /// tradeoff in an Arabic-mode sweep.
  static final RegExp identifier =
      RegExp(r'(?:ORD-\d{6}|\(?[A-Z]{2,}\d+\)?)');

  /// Returns [text] with every identifier occurrence removed — if what
  /// remains still contains a Western digit, it is a genuine violation.
  static String stripIdentifiers(String text) =>
      text.replaceAll(identifier, '');

  /// Explicit whole-string allowlist for the rare display texts that carry
  /// Western digits by design (user-data shipping snapshots in the seed).
  static const Set<String> seedAddresses = {
    '14 Nile St, Cairo',
    '8 Tahrir Sq, Cairo',
    '22 Corniche Rd, Alexandria',
    '3 Zamalek St, Cairo',
    '5 Dokki St, Giza',
    '19 Nasr City, Cairo',
  };
}

Future<void> _sweepNoWesternDigits(
  WidgetTester tester, {
  required String where,
}) async {
  final violations = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data == null) continue;
    if (_Allowed.seedAddresses.contains(data)) continue;
    // Eastern digits (٠-٩) are the *expected* rendering — only ASCII 0-9
    // trips the sweep.
    if (!RegExp(r'[0-9]').hasMatch(data)) continue;
    if (_Allowed.stripIdentifiers(data).contains(RegExp(r'[0-9]'))) {
      violations.add(data);
    }
  }
  // Editable input values (prefilled form fields like the product price
  // '20.00', stock '25') are exempt by design: what the user types or will
  // edit stays canonical, regardless of locale.
  expect(
    violations,
    isEmpty,
    reason: '$where: unexpected Western digits in Arabic display text: '
        '$violations',
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  Future<void> pumpArabicApp(WidgetTester tester) async {
    // Tall + wide: the admin rail layout, and long screens (overview) fit
    // without scrolling so the sweep sees the whole screen.
    await pumpFullApp(tester, size: const Size(900, 2200));

    // Switch to Arabic via the DI-owned LocaleCubit (the full app listens).
    await getIt<LocaleCubit>().setLocaleCode('ar');
    await settleDrift(tester); // content re-reads in the new locale
    await tester.pumpAndSettle();
  }

  Future<void> tapNav(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await settleAction(tester); // the destination's cubit watch streams
  }

  /// The pushed screens use the app's Material [AppBar], so the leading
  /// [BackButton] (not the Cupertino one pageBack() looks for) is the way
  /// back.
  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('every screen renders Eastern digits in Arabic (no Western '
      'digits outside identifiers and inputs)', (WidgetTester tester) async {
    await pumpArabicApp(tester);

    // --- Shop: catalog -----------------------------------------------
    // The catalog title carries the count ('١٣ منتجًا') — a converted digit
    // proves the sweep runs on real content.
    expect(find.text('١٣ منتجًا'), findsOneWidget);
    expect(find.text('تيشيرت كلاسيك'), findsOneWidget); // Classic Tee
    await _sweepNoWesternDigits(tester, where: 'catalog');

    // --- Product detail -----------------------------------------------
    await tester.tap(find.text('تيشيرت كلاسيك'));
    await tester.pumpAndSettle();
    await _sweepNoWesternDigits(tester, where: 'product detail');
    await goBack(tester);

    // --- Cart (empty seeded state) ------------------------------------
    await tapNav(tester, 'السلة');
    expect(find.text('سلتك فارغة'), findsOneWidget);
    await _sweepNoWesternDigits(tester, where: 'cart');

    // --- Wishlist (empty seeded state) --------------------------------
    await tapNav(tester, 'المفضلة');
    await _sweepNoWesternDigits(tester, where: 'wishlist');

    // --- Orders (seeded order numbers are allowed identifiers) ---------
    await tapNav(tester, 'الطلبات');
    expect(find.text('ORD-000001'), findsWidgets); // identifier renders
    await _sweepNoWesternDigits(tester, where: 'orders list');

    // --- Order detail --------------------------------------------------
    await tester.tap(find.text('ORD-000001').last);
    await tester.pumpAndSettle();
    // The receipt shows the seeded shipping snapshot (street numbers are
    // typed user data, kept canonical) and the coupon code inside its
    // localized label — both handled by the sweep's explicit allowlists.
    await _sweepNoWesternDigits(tester, where: 'order detail');
    await goBack(tester);

    // --- Profile ---------------------------------------------------------
    await tapNav(tester, 'الملف الشخصي');
    await _sweepNoWesternDigits(tester, where: 'profile');

    // --- Admin: gate ------------------------------------------------------
    await tester.tap(find.byKey(const Key('profile-admin-entry')));
    await settleAction(tester); // gate's isPinSet() query
    expect(find.text('تعيين رمز PIN للإدارة'), findsOneWidget);
    // The PIN hint's '4-6' converts too.
    await _sweepNoWesternDigits(tester, where: 'admin gate');

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('تعيين الرمز'));
    await settleAction(tester, delay: const Duration(milliseconds: 200));

    // --- Admin: overview --------------------------------------------------
    Finder inStatCards(String value) => find.descendant(
          of: find.byType(StatCard),
          matching: find.text(value),
        );
    expect(inStatCards('٦'), findsOneWidget); // 6 orders — converted
    expect(find.text('60% used'), findsNothing); // converted to Eastern
    await _sweepNoWesternDigits(tester, where: 'admin overview');

    // --- Admin: products list --------------------------------------------
    await tester.tap(find.text('المنتجات').last);
    await settleAction(tester);
    await _sweepNoWesternDigits(tester, where: 'admin products');

    // --- Admin: product form (edit prefill is an exempt input) -----------
    await tester.tap(find.text('تيشيرت كلاسيك').last);
    await tester.pumpAndSettle();
    await _sweepNoWesternDigits(tester, where: 'product form');
    await goBack(tester);

    // --- Admin: categories -------------------------------------------------
    await tester.tap(find.text('التصنيفات').last);
    await settleAction(tester);
    await _sweepNoWesternDigits(tester, where: 'admin categories');

    // --- Admin: coupons list -----------------------------------------------
    await tester.tap(find.text('القسائم').last);
    await settleAction(tester);
    expect(find.text('WELCOME10'), findsWidgets); // identifier renders
    await _sweepNoWesternDigits(tester, where: 'admin coupons');

    // --- Admin: coupon form ------------------------------------------------
    // The admin FABs carry unique hero tags (the shell keeps every branch
    // alive in an IndexedStack, so default tags collided here) — this push
    // is the regression guard for that fix.
    await tapAdminFab(tester);
    await _sweepNoWesternDigits(tester, where: 'coupon form');
    await goBack(tester);

    // --- Admin: orders list -----------------------------------------------
    await tester.tap(find.text('الطلبات').last);
    await settleAction(tester);
    await _sweepNoWesternDigits(tester, where: 'admin orders');

    await unmountApp(tester);
  });
}

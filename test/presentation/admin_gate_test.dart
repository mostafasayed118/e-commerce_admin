import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/gate/admin_gate_screen.dart';

import '../helpers/drift_settle.dart';
import '../helpers/storefront_exit.dart';
import '../helpers/test_di.dart';

/// Pins the gate's guidance prose digit conversion: the '4-6' range in the
/// set-PIN hint renders Eastern digits in Arabic (the same treatment the
/// pinFormat error mapping gets).
void main() {
  late AppDatabase db;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  Future<void> pumpGate(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AdminGateScreen(),
    ));
    await settleDrift(tester); // isPinSet() future
    await tester.pumpAndSettle();
  }

  testWidgets('English: the set-PIN hint keeps Western digits',
      (WidgetTester tester) async {
    await pumpGate(tester);

    expect(
      find.text('Create a 4-6 digit PIN to lock the dashboard.'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic: the 4-6 range converts to Eastern digits',
      (WidgetTester tester) async {
    await pumpGate(tester, locale: const Locale('ar'));

    expect(
      find.text('أنشئ رمز PIN من ٤-٦ أرقام لقفل لوحة التحكم.'),
      findsOneWidget,
    );
    expect(find.textContaining('4-6'), findsNothing);
  });

  group('storefront exit', () {
    testWidgets('renders beside the back button', (WidgetTester tester) async {
      await pumpGate(tester);

      expectStorefrontAction(reason: 'admin gate');
      // The standard back affordance stays too.
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('carries the localized back-to-store tooltip',
        (WidgetTester tester) async {
      await pumpGate(tester);
      expectStorefrontTooltip(const Locale('en'));

      await pumpGate(tester, locale: const Locale('ar'));
      expectStorefrontTooltip(const Locale('ar'));
    });
  });
}

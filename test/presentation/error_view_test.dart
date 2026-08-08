import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/widgets/error_view.dart';

/// Pumps the view under the app's localization delegates (ErrorView reads its
/// own l10n keys), mirroring the other shared-widget tests.
Future<void> pump(WidgetTester tester, ErrorView view, {Locale? locale}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: view),
      ),
    );

void main() {
  testWidgets('defaults to the generic title + message pair',
      (WidgetTester tester) async {
    await pump(tester, const ErrorView());

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(
      find.text("Couldn't load this right now. Please try again."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('a custom title alone omits the generic message line',
      (WidgetTester tester) async {
    // Detail screens pass their own title (couldNotLoadProduct etc.) and get
    // the title-only shape — no redundant default message underneath.
    await pump(tester, const ErrorView(title: 'Could not load product'));

    expect(find.text('Could not load product'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.textContaining("Couldn't load"), findsNothing);
  });

  testWidgets('a custom title and message render both',
      (WidgetTester tester) async {
    await pump(
      tester,
      const ErrorView(title: 'Offline', message: 'Check your connection.'),
    );

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Check your connection.'), findsOneWidget);
  });

  testWidgets('Arabic renders the localized default pair',
      (WidgetTester tester) async {
    await pump(tester, const ErrorView(), locale: const Locale('ar'));

    expect(find.text('حدث خطأ ما'), findsOneWidget);
    expect(find.text('تعذّر التحميل الآن. حاول مرة أخرى.'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });
}

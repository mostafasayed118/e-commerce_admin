import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/shells/admin_shell.dart';

/// A minimal admin shell route so [AdminShell] gets a real
/// [StatefulNavigationShell] (built by go_router — not mockable).
GoRouter adminRouter() => GoRouter(
      initialLocation: '/admin/overview',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AdminShell(navigationShell),
          branches: [
            for (final (path, label) in [
              ('/admin/overview', 'Branch Overview'),
              ('/admin/products', 'Branch Products'),
              ('/admin/categories', 'Branch Categories'),
              ('/admin/orders', 'Branch Orders'),
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) =>
                        Center(child: Text('Content $label')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

Future<void> pumpAdminShell(WidgetTester tester, {Locale? locale}) async {
  await tester.binding.setSurfaceSize(const Size(400, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: adminRouter(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
}

void main() {
  testWidgets('renders the four admin destinations with English labels',
      (WidgetTester tester) async {
    await pumpAdminShell(tester);

    for (final label in ['Overview', 'Products', 'Categories', 'Orders']) {
      expect(find.text(label), findsOneWidget);
    }
    // The admin shell is a plain shell: no destination carries a badge count.
    // (Material 3 NavigationBar wraps every destination in an internal Badge,
    // so assert on the label — a count would render text inside the Badge.)
    expect(
      find.descendant(
        of: find.byType(Badge),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
  });

  testWidgets('the destination labels follow the active locale (Arabic)',
      (WidgetTester tester) async {
    await pumpAdminShell(tester, locale: const Locale('ar'));

    for (final label in [
      'نظرة عامة',
      'المنتجات',
      'التصنيفات',
      'الطلبات',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping a destination switches to its branch',
      (WidgetTester tester) async {
    await pumpAdminShell(tester);

    // Initial branch.
    expect(find.text('Content Branch Overview'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    // The Orders branch is now active; the others are kept alive but hidden.
    expect(find.text('Content Branch Orders'), findsOneWidget);
    expect(find.text('Content Branch Overview'), findsNothing);
  });

  testWidgets('destinations() exposes the four localized labels',
      (WidgetTester tester) async {
    final labels = <String>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          labels.addAll(
            AdminShell.destinations(context).map((d) => d.label),
          );
          return const SizedBox.shrink();
        },
      ),
    ));

    expect(labels, ['Overview', 'Products', 'Categories', 'Orders']);
  });
}

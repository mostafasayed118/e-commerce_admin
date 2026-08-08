import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/seed_data.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/catalog/catalog_cubit.dart';
import 'package:shop_admin/presentation/features/catalog/catalog_sort.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/loaded_catalog.dart';
import 'package:shop_admin/presentation/features/catalog/widgets/product_card.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// Mirrors the real catalog screen's wiring (CatalogScreen provides the
/// DI-owned cubit via a value provider; the view switches on the state and
/// hands [LoadedCatalog] the loaded state) so search/filter/sort interactions
/// actually re-render through the cubit.
class _CatalogHarness extends StatelessWidget {
  const _CatalogHarness();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogCubit>.value(
      value: getIt<CatalogCubit>(),
      child: Scaffold(
        body: BlocBuilder<CatalogCubit, CatalogState>(
          builder: (context, state) => switch (state) {
            CatalogLoaded() => LoadedCatalog(state: state),
            _ => const SizedBox(),
          },
        ),
      ),
    );
  }
}

/// Pumps the catalog body on the real router (card taps push the product
/// detail route) under the app's localization delegates, then settles the
/// watch streams so the cubit emits its loaded state.
Future<GoRouter> pumpCatalog(
  WidgetTester tester, {
  Locale? locale,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _CatalogHarness()),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('detail screen'))),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
  await settleDrift(tester); // watch streams → CatalogLoaded
  await tester.pumpAndSettle();
  return router;
}

/// Pumps [LoadedCatalog] with a fixed [state] (no router — the empty state
/// renders no cards, so nothing navigates). Used to pin render branches the
/// live cubit never emits, e.g. an empty grid WITHOUT an active filter
/// (the cubit would emit CatalogEmpty instead — this branch is the widget's
/// defensive contract for a hand-constructed state).
Future<void> pumpDirect(
  WidgetTester tester, {
  required CatalogLoaded state,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<CatalogCubit>.value(
        value: getIt<CatalogCubit>(),
        child: Scaffold(body: LoadedCatalog(state: state)),
      ),
    ),
  );
  await settleDrift(tester);
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  GoRouter? router;

  setUp(() {
    db = setupTestDi();
  });

  tearDown(() async {
    // Dispose on the failure path too (tearDown always runs) — a router
    // disposed only at a test's end would leak on a mid-test assertion. The
    // pumpDirect tests never build a router, hence the nullable field; reset
    // to null so the next test's tearDown can't double-dispose the last one.
    router?.dispose();
    router = null;
    await db.close();
    await getIt.reset();
  });

  testWidgets('renders the search field, filter chips, count, and cards',
      (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = await pumpCatalog(tester);

    expect(find.text('Search products'), findsOneWidget); // field hint
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Clothing'), findsOneWidget);
    expect(find.text('13 products'), findsOneWidget); // count, locale digits
    expect(find.text('Newest'), findsOneWidget); // sort label
    // Cards render with their wishlist hearts (unfilled — empty wishlist).
    expect(find.text('Classic Tee'), findsOneWidget);
    final firstCard = tester.widget<ProductCard>(
      find.byType(ProductCard).first,
    );
    expect(firstCard.wishlisted, isFalse);

    await unmountApp(tester);
  });

  testWidgets('typing in the search field filters the grid live',
      (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = await pumpCatalog(tester);

    await tester.enterText(find.byType(TextField), 'yoga');
    // NOTE: pumpAndSettle would never settle — the focused TextField's cursor
    // blinks forever. Timed pumps only (same as catalog_flow_test).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Yoga Mat'), findsOneWidget);
    expect(find.text('Classic Tee'), findsNothing);
    expect(find.text('1 product'), findsOneWidget); // count updates

    await unmountApp(tester);
  });

  testWidgets('the one-tap clear button empties the field and restores the '
      'grid', (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = await pumpCatalog(tester);

    // No text yet -> no clear affordance.
    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(find.byType(TextField), 'yoga');
    await tester.pump(); // controller listener -> suffix appears

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    // Timed pumps only (the focused field's cursor blinks forever).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Field emptied, grid restored ('Classic Tee' is first alphabetically,
    // so it is on-screen; later products like 'Yoga Mat' stay unbuilt in the
    // lazy grid), and the clear affordance is gone again.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('an active filter with no matches shows the no-matches view '
      'and Clear filters restores the grid', (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = await pumpCatalog(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // No matches + the clear affordance (an active filter offers it).
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
    expect(find.text('Classic Tee'), findsNothing);

    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The grid is back and the search field emptied.
    expect(find.text('Classic Tee'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);

    await unmountApp(tester);
  });

  testWidgets('the sort menu applies a new sort through the cubit',
      (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = await pumpCatalog(tester);

    // Scope the first tap to the sort button (its label 'Newest' also exists
    // inside the opened menu, so an unscoped finder could hit the menu item).
    await tester.tap(
      find.descendant(
        of: find.byType(PopupMenuButton<CatalogSort>),
        matching: find.text('Newest'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: low to high'));
    await tester.pumpAndSettle();

    // The label reflects the new sort; the cubit's state did too.
    expect(find.text('Price: low to high'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('tapping a card pushes the product detail route',
      (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = await pumpCatalog(tester);

    await tester.tap(find.text('Classic Tee'));
    await settleAction(tester); // push + detail screen's watch stream

    expect(find.text('detail screen'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('Arabic renders the count in Eastern digits and Arabic names',
      (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    router = await pumpCatalog(tester, locale: const Locale('ar'));

    // 13 منتجًا — the count converts to Eastern digits.
    expect(find.text('١٣ منتجًا'), findsOneWidget);
    // The seeded Arabic product name wins over the English one.
    expect(find.text('تيشيرت كلاسيك'), findsOneWidget);
    expect(find.text('Classic Tee'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('an empty grid without an active filter shows the '
      'no-products-in-category view without Clear filters',
      (WidgetTester tester) async {
    await tester.runAsync(() => getIt<SeedData>().seedIfNeeded());
    await pumpDirect(
      tester,
      // Empty products + NO active filter: the widget's distinct empty
      // branch (different message, no clear affordance) vs. the tested
      // no-matches case. The live cubit would emit CatalogEmpty instead, so
      // this pins the widget's defensive contract directly.
      state: const CatalogLoaded(
        products: [],
        categories: [Category(id: 1, name: 'Clothing')],
      ),
    );

    // The empty view always titles "No matches"; only the message differs
    // by filter state — here the no-products-in-category variant, with no
    // clear affordance (there is no active filter to clear).
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('No products in this category yet.'), findsOneWidget);
    expect(find.text('Clear filters'), findsNothing);

    await unmountApp(tester);
  });
}

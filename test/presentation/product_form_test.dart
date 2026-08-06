import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_admin/core/di/injection.dart';
import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/product_form.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_di.dart';

/// A router hosting the form on /form so its save path (`context.pop()`)
/// can be observed; '/' is the pop target. The router starts at '/' and
/// navigates to /form, so the form is a real pushed route with '/' beneath
/// it — otherwise pop() would have nothing to return to.
GoRouter formRouter(ProductForm form) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('home'))),
        ),
        GoRoute(
          path: '/form',
          builder: (context, state) => form,
        ),
      ],
    );

Future<void> pumpForm(WidgetTester tester, ProductForm form) async {
  // Tall surface so the whole form (including the description fields and
  // the save button) is laid out without scrolling.
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = formRouter(form);
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
  // Push the form so it sits on top of '/' (pop returns to home). go()
  // would replace the stack entry, leaving pop() with nothing beneath.
  router.push('/form');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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

  Future<Category> seedCategory(WidgetTester tester) async {
    final id = await tester.runAsync(
      () => db.into(db.categories).insert(
            CategoriesCompanion.insert(name: 'Clothing', createdAt: 1),
          ),
    );
    return Category(
      id: id!,
      name: 'Clothing',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1),
    );
  }

  testWidgets('create mode blocks saving an invalid empty form',
      (WidgetTester tester) async {
    final category = await seedCategory(tester);
    await pumpForm(
      tester,
      ProductForm(product: null, categories: [category]),
    );

    expect(find.text('New product'), findsOneWidget); // AppBar title

    await tester.tap(find.text('Save product'));
    await tester.pump();

    // Inline validation errors for the empty required fields.
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Enter a price greater than 0'), findsOneWidget);

    // Nothing was persisted.
    final rows = (await tester.runAsync(() => db.select(db.products).get()))!;
    expect(rows, isEmpty);
  });

  testWidgets('edit mode prefills the form from the product',
      (WidgetTester tester) async {
    final category = await seedCategory(tester);
    final product = Product(
      id: 7,
      categoryId: category.id,
      name: 'Classic Tee',
      nameAr: 'تيشيرت كلاسيك',
      priceCents: 1234,
      discountPercent: 25,
      stock: 25,
    );
    await pumpForm(
      tester,
      ProductForm(product: product, categories: [category]),
    );

    expect(find.text('Edit product'), findsOneWidget); // AppBar title
    final name = tester
        .widget<TextFormField>(find.byKey(const Key('product-name')))
        .controller!
        .text;
    final price = tester
        .widget<TextFormField>(find.byKey(const Key('product-price')))
        .controller!
        .text;
    final discount = tester
        .widget<TextFormField>(find.byKey(const Key('product-discount')))
        .controller!
        .text;
    final stock = tester
        .widget<TextFormField>(find.byKey(const Key('product-stock')))
        .controller!
        .text;

    expect(name, 'Classic Tee');
    expect(price, '12.34'); // _centsToInput: 1234 -> "12.34"
    expect(discount, '25');
    expect(stock, '25');
  });

  testWidgets('a valid create saves through the real cubit and pops',
      (WidgetTester tester) async {
    final category = await seedCategory(tester);
    await pumpForm(
      tester,
      ProductForm(product: null, categories: [category]),
    );

    await tester.enterText(
        find.byKey(const Key('product-name')), 'Test Product');
    await tester.enterText(find.byKey(const Key('product-price')), '19.99');
    await tester.enterText(find.byKey(const Key('product-discount')), '10');
    await tester.enterText(find.byKey(const Key('product-stock')), '5');

    await tester.tap(find.text('Save product'));
    await tester.pump();
    await settleDrift(tester); // the cubit's createProduct → drift write
    // Explicit pumps for the route pop transition (pumpAndSettle can't
    // settle while the drift isolate keeps scheduling).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The router popped back to the home route.
    expect(find.text('home'), findsOneWidget);

    // The product was persisted with the exact values.
    final rows = (await tester.runAsync(() => db.select(db.products).get()))!;
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.name, 'Test Product');
    expect(row.priceCents, 1999);
    expect(row.discountPercent, 10);
    expect(row.stock, 5);
    expect(row.categoryId, category.id);
  });
}

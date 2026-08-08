import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/product_basic_fields.dart';

/// Pumps the section inside a Form so the injected name validator and the
/// built-in category validator can run (TextFormField errors only surface
/// on Form.validate()).
Future<void> pumpFields(
  WidgetTester tester,
  ProductBasicFields fields, {
  required GlobalKey<FormState> formKey,
  Locale? locale,
}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Form(key: formKey, child: fields)),
      ),
    );

ProductBasicFields fields({
  required List<Category> categories,
  int? categoryId,
  String name = '',
  String nameAr = '',
  FormFieldValidator<String>? nameValidator,
  ValueChanged<int?>? onCategoryChanged,
}) =>
    ProductBasicFields(
      nameController: TextEditingController(text: name),
      nameArController: TextEditingController(text: nameAr),
      categories: categories,
      categoryId: categoryId,
      onCategoryChanged: onCategoryChanged ?? (_) {},
      nameValidator: nameValidator ?? (_) => null,
    );

const clothing = Category(id: 1, name: 'Clothing', nameAr: 'ملابس');
const electronics = Category(id: 2, name: 'Electronics');

void main() {
  testWidgets('renders the three fields with localized labels',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(tester, fields(categories: [clothing]), formKey: formKey);

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Arabic name (optional)'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.byKey(const Key('product-name')), findsOneWidget);
    expect(find.byKey(const Key('product-name-ar')), findsOneWidget);
    expect(find.byKey(const Key('product-category')), findsOneWidget);
  });

  testWidgets('prefills the name fields and shows the selected category',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(
      tester,
      fields(
        categories: [clothing, electronics],
        categoryId: 2,
        name: 'Classic Tee',
        nameAr: 'تيشيرت كلاسيك',
      ),
      formKey: formKey,
    );

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('product-name')))
          .controller!
          .text,
      'Classic Tee',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('product-name-ar')))
          .controller!
          .text,
      'تيشيرت كلاسيك',
    );
    // The dropdown displays the selected category's label.
    expect(find.text('Electronics'), findsOneWidget);

    // With a category chosen, the built-in validator passes.
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Choose a category'), findsNothing);
  });

  testWidgets('the category dropdown lists every category and reports the choice',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    int? chosen;
    await pumpFields(
      tester,
      fields(
        categories: [clothing, electronics],
        onCategoryChanged: (id) => chosen = id,
      ),
      formKey: formKey,
    );

    await tester.tap(find.byKey(const Key('product-category')));
    await tester.pumpAndSettle();

    expect(find.text('Clothing'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);

    await tester.tap(find.text('Electronics'));
    await tester.pumpAndSettle();

    expect(chosen, 2);
  });

  testWidgets('runs the injected name validator on Form.validate and clears',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(
      tester,
      fields(
        categories: [clothing],
        nameValidator: (value) =>
            value == null || value.trim().isEmpty ? 'NAME-REQUIRED' : null,
      ),
      formKey: formKey,
    );

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('NAME-REQUIRED'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('product-name')), 'Tee');
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('NAME-REQUIRED'), findsNothing);
  });

  testWidgets('rejects a missing category via the built-in validator',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(tester, fields(categories: [clothing]), formKey: formKey);

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Choose a category'), findsOneWidget);
  });

  testWidgets('Arabic renders localized labels and the category Arabic name',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(
      tester,
      fields(categories: [clothing], categoryId: 1),
      formKey: formKey,
      locale: const Locale('ar'),
    );

    expect(find.text('الاسم'), findsOneWidget);
    expect(find.text('الاسم بالعربية (اختياري)'), findsOneWidget);
    expect(find.text('التصنيف'), findsOneWidget);
    // The selected category renders its Arabic label via context.categoryName.
    expect(find.text('ملابس'), findsOneWidget);
    expect(find.text('Name'), findsNothing);
  });
}

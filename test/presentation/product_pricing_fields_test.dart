import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/features/admin/catalog/widgets/product_pricing_fields.dart';

/// Pumps the section inside a Form so the injected validators can run
/// (TextFormField errors only surface on Form.validate()).
Future<void> pumpFields(
  WidgetTester tester,
  ProductPricingFields fields, {
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

ProductPricingFields fields({
  String price = '',
  String discount = '',
  String stock = '',
  FormFieldValidator<String>? priceValidator,
  FormFieldValidator<String>? percentValidator,
  FormFieldValidator<String>? stockValidator,
}) =>
    ProductPricingFields(
      priceController: TextEditingController(text: price),
      discountController: TextEditingController(text: discount),
      stockController: TextEditingController(text: stock),
      priceValidator: priceValidator ?? (_) => null,
      percentValidator: percentValidator ?? (_) => null,
      stockValidator: stockValidator ?? (_) => null,
    );

void main() {
  testWidgets('renders the three fields with localized labels and the dollar prefix',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(tester, fields(), formKey: formKey);

    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Discount %'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);

    // The dollar prefix and the numeric keyboard live on the field's
    // internal TextField — the price accepts decimals, discount/stock don't.
    TextField fieldOf(String key) => tester.widget<TextField>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(TextField),
          ),
        );
    expect(fieldOf('product-price').decoration?.prefixText, r'$ ');
    expect(
      fieldOf('product-price').keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(fieldOf('product-discount').keyboardType, TextInputType.number);
    expect(fieldOf('product-stock').keyboardType, TextInputType.number);
  });

  testWidgets('prefills the controllers', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(
      tester,
      fields(price: '12.34', discount: '25', stock: '5'),
      formKey: formKey,
    );

    String text(String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
    expect(text('product-price'), '12.34');
    expect(text('product-discount'), '25');
    expect(text('product-stock'), '5');
  });

  testWidgets('runs the three injected validators on Form.validate and clears',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(
      tester,
      fields(
        priceValidator: (v) => v == null || v.trim().isEmpty ? 'PRICE-ERR' : null,
        percentValidator: (v) =>
            v == null || v.trim().isEmpty ? 'PERCENT-ERR' : null,
        stockValidator: (v) =>
            v == null || v.trim().isEmpty ? 'STOCK-ERR' : null,
      ),
      formKey: formKey,
    );

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('PRICE-ERR'), findsOneWidget);
    expect(find.text('PERCENT-ERR'), findsOneWidget);
    expect(find.text('STOCK-ERR'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('product-price')), '19.99');
    await tester.enterText(find.byKey(const Key('product-discount')), '10');
    await tester.enterText(find.byKey(const Key('product-stock')), '5');
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('PRICE-ERR'), findsNothing);
    expect(find.text('PERCENT-ERR'), findsNothing);
    expect(find.text('STOCK-ERR'), findsNothing);
  });

  testWidgets('Arabic renders the localized labels', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpFields(
      tester,
      fields(),
      formKey: formKey,
      locale: const Locale('ar'),
    );

    expect(find.text('السعر'), findsOneWidget);
    expect(find.text('الخصم %'), findsOneWidget);
    expect(find.text('المخزون'), findsOneWidget);
    expect(find.text('Price'), findsNothing);
  });
}

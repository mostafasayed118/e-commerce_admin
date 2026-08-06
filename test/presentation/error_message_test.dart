import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/l10n/error_messages.dart';

/// Renders whatever string [builder] produces, so tests can exercise the
/// code → localized-message mapping inside a real Localizations context.
class _MappingProbe extends StatelessWidget {
  const _MappingProbe({required this.builder});

  final String Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) => Text(builder(context));
}

/// Pumps the probe under the app's localization delegates (Task 23 refactor:
/// the mapping functions need AppLocalizations, exactly like the screens do).
Widget probe(String Function(BuildContext) builder, {Locale? locale}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _MappingProbe(builder: builder),
    );

void main() {
  testWidgets('a plain code maps to its English message by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => errorTextForCode(context, AppErrorCode.cartEmpty),
    ));

    expect(find.text('Your cart is empty.'), findsOneWidget);
  });

  testWidgets('StockLimitError renders its data and the in-cart hint',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const StockLimitError(
          productName: 'Classic Tee',
          stock: 3,
          currentInCart: 2,
          message: 'dev log',
        ),
      ),
    ));

    expect(
      find.text(
        'Only 3 left in stock for Classic Tee. You already have 2 in your cart.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('StockLimitError without an in-cart amount omits the hint',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const StockLimitError(
          productName: 'Classic Tee',
          stock: 3,
          currentInCart: 0,
          message: 'dev log',
        ),
      ),
    ));

    expect(find.text('Only 3 left in stock for Classic Tee.'), findsOneWidget);
  });

  testWidgets('ProductOutOfStockError interpolates the product name',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const ProductOutOfStockError(
          productName: 'Leather Belt',
          message: 'dev log',
        ),
      ),
    ));

    expect(find.text('Leather Belt is out of stock.'), findsOneWidget);
  });

  testWidgets('CategoryInUseError uses the singular form for one product',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CategoryInUseError(productCount: 1, message: 'dev log'),
      ),
    ));

    expect(
      find.text(
        'This category has 1 product. Delete it before deleting the category.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('CategoryInUseError pluralizes the product count',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => localizedErrorMessage(
        context,
        const CategoryInUseError(productCount: 3, message: 'dev log'),
      ),
    ));

    expect(
      find.text(
        'This category has 3 products. Delete them before deleting the category.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the same code localizes to Arabic under the ar locale',
      (WidgetTester tester) async {
    await tester.pumpWidget(probe(
      (context) => errorTextForCode(context, AppErrorCode.pinIncorrect),
      locale: const Locale('ar'),
    ));

    expect(find.text('رمز PIN غير صحيح'), findsOneWidget);
  });
}

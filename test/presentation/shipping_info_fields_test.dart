import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/domain/usecases/checkout/validate_shipping.dart';
import 'package:shop_admin/l10n/app_localizations.dart';
import 'package:shop_admin/presentation/l10n/error_messages.dart';
import 'package:shop_admin/presentation/widgets/shipping_info_fields.dart';

/// Isolated tests for the shared [ShippingInfoFields] widget — the fields
/// used by both the checkout form and the profile form. The end-to-end
/// behavior of each host (prefill, place-order, save, dirty guard) is covered
/// by the flow tests; this file pins the widget's own contract: host keys,
/// validator wiring, error rendering and edit forwarding.
void main() {
  String? noError(String field) => null;
  String? requiredError(String field) => 'Required';

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );

  testWidgets('renders the three fields under the host-provided keys',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(_Harness(
      validateField: noError,
      nameKey: 'checkout-name',
      phoneKey: 'checkout-phone',
      addressKey: 'checkout-address',
    )));

    expect(find.byKey(const Key('checkout-name')), findsOneWidget);
    expect(find.byKey(const Key('checkout-phone')), findsOneWidget);
    expect(find.byKey(const Key('checkout-address')), findsOneWidget);

    // Localized labels render for the active (English) locale.
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Delivery address'), findsOneWidget);
  });

  testWidgets('asks the validator about every field',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(_Harness(validateField: noError)));
    await tester.tap(find.text('Validate'));
    await tester.pump();

    // Every field is wired to the validator. The call *order* is a Flutter
    // Form internal (its registration order varies with the layout — the
    // fields sit in a responsive row on wide surfaces), so the set is the
    // contract, not the sequence.
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(
      state.calls.toSet(),
      {kShippingNameField, kShippingPhoneField, kShippingAddressField},
    );
    expect(state.calls, hasLength(3));
  });

  testWidgets('renders the error message each validator returns',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(_Harness(validateField: requiredError)));
    await tester.tap(find.text('Validate'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(3));
  });

  testWidgets('forwards every edit to onChanged', (WidgetTester tester) async {
    var edits = 0;
    await tester.pumpWidget(wrap(_Harness(
      validateField: noError,
      onChanged: (_) => edits++,
    )));

    await tester.enterText(find.byKey(const Key('shipping-name')), 'Ada');
    await tester.enterText(find.byKey(const Key('shipping-phone')), '555');
    await tester.enterText(find.byKey(const Key('shipping-address')), '1 Way');

    expect(edits, 3);
  });

  testWidgets('pre-fills the fields from the bound controllers',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(_Harness(
      validateField: noError,
      initialName: 'Ada',
      initialPhone: '555-0100',
      initialAddress: '1 Analytical Way',
    )));

    final nameField =
        tester.widget<TextFormField>(find.byKey(const Key('shipping-name')));
    final phoneField =
        tester.widget<TextFormField>(find.byKey(const Key('shipping-phone')));
    final addressField =
        tester.widget<TextFormField>(find.byKey(const Key('shipping-address')));
    expect(nameField.controller!.text, 'Ada');
    expect(phoneField.controller!.text, '555-0100');
    expect(addressField.controller!.text, '1 Analytical Way');
  });

  testWidgets(
      'wires the real domain validator: empty values produce the '
      'localized required messages', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    addTearDown(() {
      name.dispose();
      phone.dispose();
      address.dispose();
    });

    late BuildContext widgetContext;
    // The same wiring the checkout/profile forms use: domain rules via
    // validateShipping, localized rendering via errorTextForCode.
    String? validateField(String field) {
      final errors = validateShipping(ShippingInfo(
        name: name.text,
        phone: phone.text,
        address: address.text,
      ));
      final code = errors[field];
      return code == null ? null : errorTextForCode(widgetContext, code);
    }

    await tester.pumpWidget(wrap(Scaffold(
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ShippingInfoFields(
              nameController: name,
              phoneController: phone,
              addressController: address,
              validateField: validateField,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => formKey.currentState!.validate(),
              child: const Text('Validate'),
            ),
          ],
        ),
      ),
    )));
    widgetContext = tester.element(find.byType(ShippingInfoFields));

    await tester.tap(find.text('Validate'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    expect(find.text('Address is required'), findsOneWidget);
  });
}

/// Owns the controllers + form and exposes the field ids the validator was
/// asked about ([_HarnessState.calls]) so tests can pin the wiring.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.validateField,
    this.onChanged,
    this.nameKey = 'shipping-name',
    this.phoneKey = 'shipping-phone',
    this.addressKey = 'shipping-address',
    this.initialName = '',
    this.initialPhone = '',
    this.initialAddress = '',
  });

  final String? Function(String field) validateField;
  final ValueChanged<String>? onChanged;
  final String nameKey;
  final String phoneKey;
  final String addressKey;
  final String initialName;
  final String initialPhone;
  final String initialAddress;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name =
      TextEditingController(text: widget.initialName);
  late final TextEditingController phone =
      TextEditingController(text: widget.initialPhone);
  late final TextEditingController address =
      TextEditingController(text: widget.initialAddress);

  /// The field ids the validator was asked about, in validation order.
  final List<String> calls = [];

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  String? _validate(String field) {
    calls.add(field);
    return widget.validateField(field);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ShippingInfoFields(
              nameController: name,
              phoneController: phone,
              addressController: address,
              validateField: _validate,
              nameKey: widget.nameKey,
              phoneKey: widget.phoneKey,
              addressKey: widget.addressKey,
              onChanged: widget.onChanged,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => formKey.currentState!.validate(),
              child: const Text('Validate'),
            ),
          ],
        ),
      ),
    );
  }
}

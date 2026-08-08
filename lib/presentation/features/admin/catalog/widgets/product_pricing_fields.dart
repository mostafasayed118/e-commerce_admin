import 'package:flutter/material.dart';

import '../../../../l10n/l10n_ext.dart';
import '../../../../widgets/responsive/responsive_form_row.dart';

/// The product form's pricing section: price + discount on one row, then
/// stock. Controllers and validators are owned by the form's state and
/// passed in.
class ProductPricingFields extends StatelessWidget {
  const ProductPricingFields({
    super.key,
    required this.priceController,
    required this.discountController,
    required this.stockController,
    required this.priceValidator,
    required this.percentValidator,
    required this.stockValidator,
  });

  final TextEditingController priceController;
  final TextEditingController discountController;
  final TextEditingController stockController;
  final FormFieldValidator<String> priceValidator;
  final FormFieldValidator<String> percentValidator;
  final FormFieldValidator<String> stockValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // All three fields share one row on wide surfaces (they're short numeric
    // inputs) and stack on phones.
    return ResponsiveFormRow(
      children: [
        TextFormField(
          key: const Key('product-price'),
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: l10n.price,
            prefixText: r'$ ',
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          validator: priceValidator,
        ),
        TextFormField(
          key: const Key('product-discount'),
          controller: discountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.discountPercent,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          validator: percentValidator,
        ),
        TextFormField(
          key: const Key('product-stock'),
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.stock,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          validator: stockValidator,
        ),
      ],
    );
  }
}

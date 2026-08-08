import 'package:flutter/material.dart';

import '../../domain/usecases/checkout/validate_shipping.dart';
import '../l10n/l10n_ext.dart';
import 'responsive/responsive_form_row.dart';

/// The three shipping-address fields (name / phone / address) shared by the
/// checkout form and the profile form — one copy so the two forms can never
/// drift apart. Both hosts validate through the same domain rules
/// (validate_shipping.dart) via [validateField], which maps a
/// `kShipping*Field` id to its localized error text (or null when valid).
///
/// The field keys are parameterized ([nameKey] / [phoneKey] / [addressKey])
/// so each host screen keeps its own stable test keys. [onChanged] is
/// optional — the profile form uses it to arm its dirty guard; checkout
/// passes nothing.
class ShippingInfoFields extends StatelessWidget {
  const ShippingInfoFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.validateField,
    this.nameKey = 'shipping-name',
    this.phoneKey = 'shipping-phone',
    this.addressKey = 'shipping-address',
    this.onChanged,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  /// Maps a `kShipping*Field` id to a localized error message, or null when
  /// the field's current value is valid.
  final String? Function(String field) validateField;

  final String nameKey;
  final String phoneKey;
  final String addressKey;

  /// Called after every edit in any of the three fields.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Name + phone sit side by side on wide surfaces (they're short fields)
    // and stack on phones; the address always takes the full width.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveFormRow(
          children: [
            TextFormField(
              key: Key(nameKey),
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onChanged: onChanged,
              validator: (_) => validateField(kShippingNameField),
            ),
            TextFormField(
              key: Key(phoneKey),
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phone,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: onChanged,
              validator: (_) => validateField(kShippingPhoneField),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: Key(addressKey),
          controller: addressController,
          decoration: InputDecoration(
            labelText: l10n.deliveryAddress,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
          textInputAction: TextInputAction.newline,
          onChanged: onChanged,
          validator: (_) => validateField(kShippingAddressField),
        ),
      ],
    );
  }
}

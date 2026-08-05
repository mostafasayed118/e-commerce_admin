import '../../../core/entities/shipping_info.dart';

/// Field keys used in the returned error map.
const String kShippingNameField = 'name';
const String kShippingPhoneField = 'phone';
const String kShippingAddressField = 'address';

/// Validates a checkout shipping form.
///
/// Returns a map of field -> error message, **empty when valid**. Field-level
/// keys let the checkout form render each error under its input; [PlaceOrder]
/// only needs `isEmpty`. Rules are deliberately minimal — every field must be
/// non-empty after trimming. Phone formats vary wildly across regions (the
/// seed data uses `0100 000 0001`), so no format guessing here; the
/// repository never sees an invalid form because [PlaceOrder] rejects first.
Map<String, String> validateShipping(ShippingInfo shipping) {
  final errors = <String, String>{};

  if (shipping.name.trim().isEmpty) {
    errors[kShippingNameField] = 'Name is required';
  }
  if (shipping.phone.trim().isEmpty) {
    errors[kShippingPhoneField] = 'Phone is required';
  }
  if (shipping.address.trim().isEmpty) {
    errors[kShippingAddressField] = 'Address is required';
  }
  return errors;
}

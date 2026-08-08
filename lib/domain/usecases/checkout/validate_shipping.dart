import '../../../core/entities/shipping_info.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';

/// Field keys used in the returned error map.
const String kShippingNameField = 'name';
const String kShippingPhoneField = 'phone';
const String kShippingAddressField = 'address';

/// Validates a checkout shipping form.
///
/// Returns a map of field -> [AppErrorCode], **empty when valid**. Field-level
/// keys let the checkout form render each error under its input; [PlaceOrder]
/// only needs `isEmpty`. Values are stable codes (not display strings) so the
/// UI renders them in the active locale (Task 23 refactor). Rules are
/// deliberately minimal — every field must be non-empty after trimming. Phone
/// formats vary wildly across regions (the seed data uses `0100 000 0001`),
/// so no format guessing here; the repository never sees an invalid form
/// because [PlaceOrder] rejects first.
Map<String, AppErrorCode> validateShipping(ShippingInfo shipping) {
  final errors = <String, AppErrorCode>{};

  if (shipping.name.trim().isEmpty) {
    errors[kShippingNameField] = AppErrorCode.nameRequired;
  }
  if (shipping.phone.trim().isEmpty) {
    errors[kShippingPhoneField] = AppErrorCode.phoneRequired;
  }
  if (shipping.address.trim().isEmpty) {
    errors[kShippingAddressField] = AppErrorCode.addressRequired;
  }
  return errors;
}

/// Trims [input] and validates it, returning the normalized profile on
/// success or a [ValidationError] carrying the first failing field's code
/// (the English text stays for logs; the UI maps the code to the locale).
///
/// Shared by the order-placement and profile-save use cases — the two
/// writers of the same single-row profile table — so their
/// normalize → validate → fail contract literally cannot drift apart.
Result<ShippingInfo> normalizeAndValidateShipping(ShippingInfo input) {
  final normalized = ShippingInfo(
    name: input.name.trim(),
    phone: input.phone.trim(),
    address: input.address.trim(),
  );
  final errors = validateShipping(normalized);
  if (errors.isNotEmpty) {
    return Failure(ValidationError(
      code: errors.values.first,
      message: 'Validation failed: ${errors.values.first.name}',
    ));
  }
  return Success(normalized);
}

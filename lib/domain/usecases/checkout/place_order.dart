import '../../../core/entities/order.dart';
import '../../../core/entities/shipping_info.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/settings_repository.dart';
import 'validate_shipping.dart';

/// Places an order from the current cart.
///
/// The single entry point the checkout screen calls: trims and
/// validates the shipping form, delegates the atomic placement to
/// [OrderRepository.placeOrder] (stock re-validation, snapshot, cart clear —
/// Task 8), then persists the shipping details as the customer profile for
/// next-time pre-fill.
///
/// [saveProfile] defaults to true so the checkout form can offer a
/// "save my details" toggle. Profile persistence is **best-effort**: neither
/// a returned [Failure] nor a thrown exception may undo or surface alongside
/// an already-placed order (the try/catch below makes that contract real,
/// not just documented).
class PlaceOrder {
  PlaceOrder(this._orders, this._settings);

  final OrderRepository _orders;
  final SettingsRepository _settings;

  Future<Result<Order>> call(
    ShippingInfo shipping, {
    bool saveProfile = true,
  }) async {
    // Normalize once: validation trims for the emptiness check, and both the
    // order snapshot and the saved profile should carry clean values.
    final normalized = ShippingInfo(
      name: shipping.name.trim(),
      phone: shipping.phone.trim(),
      address: shipping.address.trim(),
    );

    final errors = validateShipping(normalized);
    if (errors.isNotEmpty) {
      // The first failing field's stable code; the English text stays for
      // logs (the UI maps the code to the active locale).
      final code = errors.values.first;
      return Failure(ValidationError(
        code: code,
        message: 'Validation failed: ${code.name}',
      ));
    }

    final result = await _orders.placeOrder(normalized);
    if (result.isSuccess && saveProfile) {
      try {
        await _settings.updateProfile(normalized);
      } on Exception {
        // Best-effort: a failed convenience save must never undo or break an
        // already-placed order. The order result is returned as-is either way.
      }
    }
    return result;
  }
}

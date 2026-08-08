import '../../../core/entities/order.dart';
import '../../../core/entities/shipping_info.dart';
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
    String? couponCode,
  }) =>
      // Normalize once and validate — shared with the profile-save use case
      // so the two writers of the single-row profile table can never disagree
      // on the rules (both the order snapshot and the saved profile get clean
      // values). flatMapAsync hands a validation failure back unchanged and
      // feeds the clean value to the placement — same shape as SaveProfile.
      normalizeAndValidateShipping(shipping).flatMapAsync((normalized) async {
        final result = await _orders.placeOrder(
          normalized,
          couponCode: couponCode,
        );
        if (result.isSuccess && saveProfile) {
          try {
            await _settings.updateProfile(normalized);
          } on Exception {
            // Best-effort: a failed convenience save must never undo or break
            // an already-placed order. The order result is returned as-is
            // either way.
          }
        }
        return result;
      });
}

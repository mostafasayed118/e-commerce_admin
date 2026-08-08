import '../../../core/entities/shipping_info.dart';
import '../../../core/error/result.dart';
import '../../repositories/settings_repository.dart';
import '../checkout/validate_shipping.dart';

/// Saves the customer profile (the shipping details used to pre-fill
/// checkout).
///
/// The profile screen's domain gate: normalize → validate → persist through
/// the same [normalizeAndValidateShipping] rule as the order placement use
/// case, so the two writers of the same single-row table can never disagree.
/// The screen's field validators reuse the *same* [validateShipping] for
/// inline errors; this use case re-validates as defense in depth (the
/// repository itself is a dumb storage gate, per Decision A).
class SaveProfile {
  SaveProfile(this._settings);

  final SettingsRepository _settings;

  Future<Result<void>> call(ShippingInfo profile) =>
      // Normalize once and validate — shared with the order placement use
      // case (the stored profile and the checkout pre-fill both carry clean
      // values). flatMapAsync hands a validation failure back unchanged and
      // feeds the clean value to the write — the same shape as PlaceOrder.
      normalizeAndValidateShipping(profile).flatMapAsync(_settings.updateProfile);
}

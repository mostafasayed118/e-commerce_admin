import '../../../core/entities/shipping_info.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../repositories/settings_repository.dart';
import '../checkout/validate_shipping.dart';

/// Saves the customer profile (the shipping details used to pre-fill
/// checkout).
///
/// The profile screen's domain gate, mirroring [PlaceOrder]'s own
/// normalize → validate → persist flow so the two writers of the same
/// single-row table can never disagree on the rules. The screen's field
/// validators reuse the *same* [validateShipping] for inline errors; this
/// use case re-validates as defense in depth (the repository itself is a
/// dumb storage gate, per Decision A).
class SaveProfile {
  SaveProfile(this._settings);

  final SettingsRepository _settings;

  Future<Result<void>> call(ShippingInfo profile) async {
    // Normalize once, like PlaceOrder: both the stored profile and the
    // checkout pre-fill should carry clean values.
    final normalized = ShippingInfo(
      name: profile.name.trim(),
      phone: profile.phone.trim(),
      address: profile.address.trim(),
    );

    final errors = validateShipping(normalized);
    if (errors.isNotEmpty) {
      return Failure(ValidationError(message: errors.values.first));
    }

    return _settings.updateProfile(normalized);
  }
}

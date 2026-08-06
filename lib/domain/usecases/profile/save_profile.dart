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
      // The first failing field's stable code; the English text stays for
      // logs (the UI maps the code to the active locale).
      final code = errors.values.first;
      return Failure(ValidationError(
        code: code,
        message: 'Validation failed: ${code.name}',
      ));
    }

    return _settings.updateProfile(normalized);
  }
}

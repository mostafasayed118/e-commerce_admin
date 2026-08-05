import '../../core/entities/shipping_info.dart';
import '../../core/entities/ui_prefs.dart';
import '../../core/error/result.dart';

/// Read/write access to local user settings: the customer [ShippingInfo]
/// profile (checkout pre-fill) and the admin PIN gate.
///
/// The PIN is stored as a salted SHA-256 hash only — never the raw PIN
/// (Decision B, Option 2). One-shot operations return [Result]; watch
/// streams carry plain data (consistent with the other repositories).
abstract interface class SettingsRepository {
  // --- Customer profile ---------------------------------------------------

  /// Reactive profile; emits `null` until first saved.
  Stream<ShippingInfo?> watchProfile();

  Future<Result<ShippingInfo?>> getProfile();

  /// Saves the profile, stamping the stored row's `updatedAt` (the entity
  /// itself carries no timestamp — it lives on the DB row). Upserts the
  /// single row (id = 1) — never duplicates.
  Future<Result<void>> updateProfile(ShippingInfo profile);

  // --- UI preferences -----------------------------------------------------

  /// Reactive preferences; emits an (empty) [UiPrefs] even before any save.
  Stream<UiPrefs> watchUiPrefs();

  Future<Result<UiPrefs>> getUiPrefs();

  /// Upserts the single prefs row. Fields not passed keep their stored
  /// value (absent companion columns merge on conflict) — theme and locale
  /// share one row with no read-modify-write.
  Future<Result<void>> updateUiPrefs({
    String? themeModeCode,
    String? localeCode,
  });

  // --- Admin PIN gate -----------------------------------------------------

  /// Whether a PIN has been set. The gate screen branches on this: show the
  /// "set a PIN" form when false, the "enter PIN" form when true.
  Future<Result<bool>> isPinSet();

  /// Sets (or replaces) the PIN. [pin] must match the 4-6 digit format —
  /// [ValidationError] otherwise. Persists only the salted hash.
  Future<Result<void>> setPin(String pin);

  /// Success when [pin] matches the stored hash; [PinError] when the PIN is
  /// not set or is wrong (distinct messages for the gate UI).
  Future<Result<void>> verifyPin(String pin);
}

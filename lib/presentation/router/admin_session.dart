/// Tracks whether the admin area is unlocked for this app session.
///
/// A deliberate, documented simplification of "authentication": the PIN gate
/// (Task 9's `SettingsRepository`) proves knowledge of the PIN once, and this
/// flag lets the router guard pass subsequent admin navigation until the app
/// is restarted. No expiry, no logout — appropriate for a local-only mock
/// gate; the real auth story is explicitly out of scope.
class AdminSession {
  /// Whether [verifyPin] has succeeded (or a PIN has just been set) this
  /// session.
  bool unlocked = false;
}

/// Security helpers for the admin PIN gate (Decision B, Option 2).
///
/// Only a salted hash is ever persisted — never the PIN itself. Each install
/// generates a fresh random salt, so identical PINs produce different hashes
/// and a leaked hash reveals nothing about the PIN.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generates a random salt: 16 bytes from a cryptographically secure source,
/// base64-encoded. No seed, no predictable sequence.
String generateSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Encode(bytes);
}

/// One-way hash of [pin] with [salt]. SHA-256 is used because this is a
/// *mock* auth gate — PBKDF2/argon2 (real-auth-grade KDFs) would be
/// over-engineering for a locally verified demo PIN (see pubspec note).
///
/// The salt is bound into the input (`salt:pin`), so the same PIN with a
/// different salt yields a different hash. Deterministic for a given
/// (pin, salt) pair — that is what makes verification possible.
String hashPin(String pin, String salt) {
  final digest = sha256.convert(utf8.encode('$salt:$pin'));
  return digest.toString();
}

/// Valid PIN format for the gate: 4-6 digits.
final RegExp pinPattern = RegExp(r'^\d{4,6}$');

/// Whether [pin] satisfies the gate's format rule. Enforced at the repository
/// boundary (the DB stores only the opaque hash, so it cannot CHECK this).
bool isValidPin(String pin) => pinPattern.hasMatch(pin);

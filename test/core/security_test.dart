import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/utils/security.dart';

void main() {
  group('hashPin', () {
    test('is deterministic for the same pin and salt', () {
      expect(hashPin('1234', 'salt-a'), hashPin('1234', 'salt-a'));
    });

    test('differs across salts (salted, not plain hashing)', () {
      expect(hashPin('1234', 'salt-a'), isNot(hashPin('1234', 'salt-b')));
    });

    test('differs across pins with the same salt', () {
      expect(hashPin('1234', 'salt-a'), isNot(hashPin('5678', 'salt-a')));
    });

    test('never contains the raw pin', () {
      final hash = hashPin('987654', 'demo-salt');
      expect(hash, isNot(contains('987654')));
      expect(hash, isNot(contains('demo-salt')));
    });

    test('produces a 64-char hex digest', () {
      expect(hashPin('1234', 'salt'), matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('generateSalt', () {
    test('produces unique, url-safe base64 values', () {
      final salts = {for (var i = 0; i < 50; i++) generateSalt()};
      expect(salts, hasLength(50), reason: 'salts must be unique per call');
      for (final salt in salts) {
        expect(salt, matches(RegExp(r'^[A-Za-z0-9+/=]+$')));
        expect(salt.length, greaterThanOrEqualTo(20),
            reason: '16 random bytes base64-encoded');
      }
    });
  });

  group('isValidPin', () {
    test('accepts 4-6 digit pins', () {
      expect(isValidPin('1234'), isTrue);
      expect(isValidPin('123456'), isTrue);
    });

    test('rejects too short, too long, and non-digit pins', () {
      expect(isValidPin(''), isFalse);
      expect(isValidPin('123'), isFalse);
      expect(isValidPin('1234567'), isFalse);
      expect(isValidPin('12a4'), isFalse);
      expect(isValidPin('123 4'), isFalse);
    });
  });
}

/// Money helpers.
///
/// Prices are stored as integer *cents* — never `double` — so all arithmetic
/// is exact. (Floating point cannot represent $0.10 exactly, which would
/// corrupt totals and discounts.) Formatting is hand-rolled to avoid an
/// `intl` dependency; localization is out of scope for this project.
library;

/// Formats an integer cent amount as a currency string: `1234 -> "$12.34"`.
String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final centsPart = (abs % 100).toString().padLeft(2, '0');
  return '$sign\$${_groupThousands(dollars)}.$centsPart';
}

/// Groups digits with thousands separators: `1234567 -> "1,234,567"`.
String _groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Price after a percentage discount, computed with integer math
/// (`~/` floors): `priceCents * (100 - discountPercent) ~/ 100`.
///
/// Preconditions: `priceCents >= 0`, `0 <= discountPercent <= 100` — enforced
/// with debug-only asserts as a backstop (UI validation stays the UX layer,
/// same philosophy as the DB CHECK constraints).
int discountedPriceCents(int priceCents, int discountPercent) {
  assert(priceCents >= 0, 'price must be non-negative');
  assert(
    discountPercent >= 0 && discountPercent <= 100,
    'discount must be between 0 and 100',
  );
  return priceCents * (100 - discountPercent) ~/ 100;
}

/// The amount saved by the discount, in cents.
int discountAmountCents(int priceCents, int discountPercent) {
  assert(priceCents >= 0, 'price must be non-negative');
  assert(
    discountPercent >= 0 && discountPercent <= 100,
    'discount must be between 0 and 100',
  );
  return priceCents - discountedPriceCents(priceCents, discountPercent);
}

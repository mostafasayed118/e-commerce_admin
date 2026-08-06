/// Money helpers.
///
/// Prices are stored as integer *cents* — never `double` — so all arithmetic
/// is exact. (Floating point cannot represent $0.10 exactly, which would
/// corrupt totals and discounts.) Formatting delegates to `intl`'s
/// [NumberFormat] so grouping, decimal separators and digit shapes follow the
/// active locale (Task 23): en `1234 -> "$12.34"`, ar `-> "١٢٫٣٤ $"`.
///
/// NOTE: [formatCents] converts to a double only for *display* — cents/100 is
/// within 1e-14 of the true value, and NumberFormat's 2-decimal rounding
/// always recovers the exact cents. The "integer math" doctrine governs
/// arithmetic, not presentation.
library;

import 'package:intl/intl.dart';

/// Formats an integer cent amount as a currency string for [locale].
///
/// The symbol stays `$` — the app has no multi-currency concept (cents are
/// generic), so localization changes *presentation*, never the stored value.
/// English output is byte-identical to the previous hand-rolled formatter
/// (e.g. `123456 -> "$1,234.56"`, `-1234 -> "-$12.34"`).
String formatCents(int cents, {String locale = 'en'}) =>
    NumberFormat.currency(locale: locale, symbol: r'$').format(cents / 100);

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

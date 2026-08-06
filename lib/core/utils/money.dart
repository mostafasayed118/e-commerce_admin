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
/// (e.g. `123456 -> "$1,234.56"`, `-1234 -> "-$12.34"`). The `ar` locale's
/// digits are translated to Eastern Arabic numerals by [arabicIndicDigits]
/// so prices render like the dates ("‏١٢٫٣٤ $").
String formatCents(int cents, {String locale = 'en'}) => arabicIndicDigits(
      NumberFormat.currency(locale: locale, symbol: r'$').format(cents / 100),
      locale,
    );

// 0-9 -> ٠-٩ (U+0660..U+0669), the Eastern Arabic numerals used by the ar
// locale's conventional script.
const String _arabicIndicZeroDigit = '\u0660';

/// Translates Western digits in [text] to Eastern Arabic numerals for the
/// `ar` locale; any other locale returns [text] unchanged.
///
/// intl's [NumberFormat] and [DateFormat] render pattern digits themselves
/// and do not consume a custom [NumberSymbols] for those fields, so the clean
/// way to get Arabic-Indic digits (dates, prices) without globally
/// re-registering the locale's number symbols is this deterministic
/// substitution on the formatted string. English output is byte-identical.
String arabicIndicDigits(String text, String locale) {
  if (locale != 'ar') return text;
  final buffer = StringBuffer();
  for (final unit in text.runes) {
    // 0x30..0x39 are ASCII '0'..'9'.
    buffer.writeCharCode(
      unit >= 0x30 && unit <= 0x39
          ? _arabicIndicZeroDigit.codeUnitAt(0) + (unit - 0x30)
          : unit,
    );
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

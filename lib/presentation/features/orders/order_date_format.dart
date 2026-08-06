/// Locale-aware date formatting for orders (Task 23).
///
/// One fixed skeleton (`d MMM yyyy`) is applied in every locale so the shape
/// stays stable; intl supplies the localized month names and digit shapes.
/// English output is byte-identical to the previous hand-rolled formatter
/// ("5 Aug 2026", "5 Aug 2026, 09:05"); Arabic renders Arabic month names and
/// digits ("٥ أغسطس ٢٠٢٦").
///
/// intl only preloads date symbols for the default locale, so Arabic (and any
/// other) needs `initializeDateFormatting`. It is called lazily on first use
/// — its body registers ALL locales synchronously (the returned future is
/// already complete) — so the formatter works in any entry point (app, widget
/// tests, unit tests) without a hand-placed init call.
library;

// DateFormat only ships the default locale's symbols; importing this file
// exposes `initializeDateFormatting`, whose synchronous body registers ALL
// locales (see _ensureDateSymbols below).
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/money.dart';

bool _dateSymbolsInitialized = false;

void _ensureDateSymbols() {
  if (_dateSymbolsInitialized) return;
  _dateSymbolsInitialized = true;
  initializeDateFormatting();
}

/// `DateTime(2026, 8, 5) -> "5 Aug 2026"` (en).
String formatOrderDate(DateTime date, {String locale = 'en'}) {
  _ensureDateSymbols();
  return arabicIndicDigits(
    DateFormat('d MMM yyyy', locale).format(date),
    locale,
  );
}

/// `DateTime(2026, 8, 5, 9, 5) -> "5 Aug 2026, 09:05"` (en, for timeline
/// entries).
String formatOrderDateTime(DateTime date, {String locale = 'en'}) {
  _ensureDateSymbols();
  return arabicIndicDigits(
    DateFormat('d MMM yyyy, HH:mm', locale).format(date),
    locale,
  );
}

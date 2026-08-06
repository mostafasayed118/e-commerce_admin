import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/presentation/features/orders/order_date_format.dart';

void main() {
  final date = DateTime(2026, 8, 5);
  final dateTime = DateTime(2026, 8, 5, 9, 5);

  group('formatOrderDate', () {
    test('renders the stable d MMM yyyy skeleton in English', () {
      expect(formatOrderDate(date), '5 Aug 2026');
    });

    test('renders Arabic month names and Eastern Arabic numerals under ar', () {
      expect(formatOrderDate(date, locale: 'ar'), '٥ أغسطس ٢٠٢٦');
    });

    test('a single-digit day is not zero-padded', () {
      expect(formatOrderDate(DateTime(2026, 3, 7)), '7 Mar 2026');
    });
  });

  group('formatOrderDateTime', () {
    test('renders the date plus a 24h time in English', () {
      expect(formatOrderDateTime(dateTime), '5 Aug 2026, 09:05');
    });

    test('an afternoon time is not 12h-converted', () {
      expect(
        formatOrderDateTime(DateTime(2026, 8, 5, 17, 45)),
        '5 Aug 2026, 17:45',
      );
    });

    test('renders Eastern Arabic numerals in the time under ar', () {
      // Digits are translated; the pattern's literal comma/space separators
      // are left as-is by intl.
      expect(
        formatOrderDateTime(dateTime, locale: 'ar'),
        '٥ أغسطس ٢٠٢٦, ٠٩:٠٥',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/utils/money.dart';

void main() {
  group('formatCents', () {
    test('formats zero', () {
      expect(formatCents(0), r'$0.00');
    });

    test('formats sub-dollar amounts with leading zero', () {
      expect(formatCents(5), r'$0.05');
      expect(formatCents(99), r'$0.99');
    });

    test('formats whole dollars with two cent digits', () {
      expect(formatCents(100), r'$1.00');
      expect(formatCents(1200), r'$12.00');
    });

    test('groups thousands with commas', () {
      expect(formatCents(123456), r'$1,234.56');
      expect(formatCents(1000000), r'$10,000.00');
    });

    test('handles negative amounts', () {
      expect(formatCents(-1234), r'-$12.34');
    });

    test('follows the active locale (Task 23)', () {
      // intl's 'ar' renders Western digits with RTL-adjusted placement and
      // a space before the symbol (Gulf convention); assert the stable
      // parts, not the leading RTL mark.
      final ar = formatCents(1234, locale: 'ar');
      expect(ar, contains('12.34'));
      expect(ar, contains(r'$'));
    });
  });

  group('discountedPriceCents', () {
    test('no discount returns the full price', () {
      expect(discountedPriceCents(10000, 0), 10000);
    });

    test('full discount returns zero', () {
      expect(discountedPriceCents(10000, 100), 0);
    });

    test('applies the percentage with integer math', () {
      expect(discountedPriceCents(10000, 50), 5000);
      expect(discountedPriceCents(10000, 20), 8000);
    });

    test('floors fractional cents rather than rounding', () {
      // 999 * 67 = 66933, ~/ 100 = 669 (the 0.33 remainder is dropped).
      expect(discountedPriceCents(999, 33), 669);
    });
  });

  group('discountAmountCents', () {
    test('computes the saved amount', () {
      expect(discountAmountCents(10000, 20), 2000);
      expect(discountAmountCents(999, 33), 330);
    });
  });
}

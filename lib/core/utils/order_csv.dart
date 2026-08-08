import 'dart:convert';

import '../entities/order.dart';
import '../entities/order_item.dart';

/// Orders serialized to CSV for the admin export.
///
/// Deliberately **locale-independent**: CSV is data for spreadsheets, not
/// UI. Dates are ISO-8601 (`yyyy-MM-dd`) so they parse in any locale, money
/// is plain decimal (no currency symbol), statuses use the enum's stable
/// English label. Arabic content survives via UTF-8 with a BOM — without the
/// BOM, Excel opens the file as ANSI and Arabic names/addresses become
/// mojibake.
///
/// RFC 4180: fields containing a comma, quote or line break are quoted and
/// embedded quotes are doubled; rows end with CRLF.
List<int> ordersToCsvBytes(List<Order> orders) {
  final rows = <String>[
    _row(const [
      'Order',
      'Date',
      'Status',
      'Customer',
      'Phone',
      'Address',
      'Subtotal',
      'Discount',
      'Total',
      'Coupon',
      'Items',
    ]),
    for (final order in orders)
      _row([
        order.orderNumber,
        order.createdAt == null ? '' : isoDate(order.createdAt!),
        order.status.label,
        order.shipping.name,
        order.shipping.phone,
        order.shipping.address,
        _money(order.subtotalCents),
        _money(order.discountCents),
        _money(order.totalCents),
        order.couponCode ?? '',
        order.items.map(_item).join('; '),
      ]),
  ];
  // UTF-8 BOM so Excel detects UTF-8 (Arabic names survive).
  return [0xEF, 0xBB, 0xBF, ...utf8.encode(rows.join('\r\n') + '\r\n')];
}

/// `DateTime(2026, 3, 7) -> '2026-03-07'`. Zero-padded, locale-independent
/// (also used for the export file's suggested name).
String isoDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}

String _row(List<String> fields) => fields.map(_field).join(',');

/// RFC 4180 field escaping: quote when the value contains a comma, quote or
/// line break; double embedded quotes.
String _field(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _item(OrderItem item) => '${item.productName} x${item.quantity}';

/// Cents to a plain two-decimal string (no currency symbol — spreadsheets
/// should treat it as a number).
String _money(int cents) => (cents / 100).toStringAsFixed(2);

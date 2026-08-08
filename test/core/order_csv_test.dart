import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';
import 'package:shop_admin/core/utils/order_csv.dart';

void main() {
  Order order({
    int id = 1,
    String orderNumber = 'ORD-000001',
    OrderStatus status = OrderStatus.pending,
    int subtotalCents = 10000,
    int discountCents = 500,
    int totalCents = 9500,
    String? couponCode,
    DateTime? createdAt,
    ShippingInfo shipping = const ShippingInfo(name: 'A', phone: '1', address: 'St'),
    List<OrderItem> items = const [],
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      status: status,
      subtotalCents: subtotalCents,
      discountCents: discountCents,
      totalCents: totalCents,
      couponCode: couponCode,
      createdAt: createdAt,
      shipping: shipping,
      items: items,
    );
  }

  /// Decodes the body past the UTF-8 BOM, keeping the CRLF endings.
  String body(List<int> bytes) => utf8.decode(bytes.skip(3).toList());

  test('every export starts with the UTF-8 BOM', () {
    final bytes = ordersToCsvBytes(const []);
    expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
  });

  test('an empty list yields just the header row (CRLF terminated)', () {
    expect(
      body(ordersToCsvBytes(const [])),
      'Order,Date,Status,Customer,Phone,Address,Subtotal,Discount,Total,'
      'Coupon,Items\r\n',
    );
  });

  test('a full order renders one RFC 4180 row with ISO date and plain money',
      () {
    final text = body(ordersToCsvBytes([
      order(createdAt: DateTime(2026, 7, 1, 9, 30)),
    ]));
    final lines = text.trim().split('\r\n');
    expect(lines, hasLength(2));
    expect(
      lines[1],
      'ORD-000001,2026-07-01,Pending,A,1,St,100.00,5.00,95.00,,',
    );
  });

  test('fields containing commas or quotes are quoted and escaped', () {
    final lines = body(ordersToCsvBytes([
      order(
        shipping: const ShippingInfo(
          name: 'Ali, "The Great"',
          phone: '1',
          address: 'Main\nSt',
        ),
      ),
    ])).trim().split('\r\n');
    expect(lines[1], contains('"Ali, ""The Great"""'));
    expect(lines[1], contains('"Main\nSt"'));
  });

  test('coupon code and item lines are included; Arabic survives UTF-8', () {
    final text = body(ordersToCsvBytes([
      order(
        couponCode: 'SAVE10',
        items: const [
          OrderItem(
            orderId: 1,
            productName: 'تيشيرت',
            quantity: 2,
            unitPriceCents: 1000,
          ),
        ],
      ),
    ]));
    expect(text, contains('SAVE10'));
    expect(text, contains('تيشيرت x2'));
  });

  test('ISO dates are zero-padded and single-digit days are not padded over',
      () {
    final text = body(ordersToCsvBytes([
      order(createdAt: DateTime(2026, 3, 7)),
    ]));
    expect(text, contains(',2026-03-07,'));
  });
}

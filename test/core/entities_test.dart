import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/cart_item.dart';
import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/entities/order.dart';
import 'package:shop_admin/core/entities/order_item.dart';
import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/entities/shipping_info.dart';

void main() {
  group('Product', () {
    test('derives the discounted price with integer math', () {
      const product = Product(
        id: 1,
        categoryId: 1,
        name: 'T-Shirt',
        priceCents: 2000,
        discountPercent: 25,
      );
      expect(product.hasDiscount, isTrue);
      expect(product.finalPriceCents, 1500);
      expect(product.savingsCents, 500);
    });

    test('no discount keeps the price and hasDiscount false', () {
      const product = Product(id: 1, categoryId: 1, name: 'Socks', priceCents: 500);
      expect(product.hasDiscount, isFalse);
      expect(product.finalPriceCents, 500);
      expect(product.savingsCents, 0);
    });

    test('flags stock status correctly', () {
      const inStock = Product(id: 1, categoryId: 1, name: 'A', priceCents: 100, stock: 10);
      const low = Product(id: 2, categoryId: 1, name: 'B', priceCents: 100, stock: 5);
      const out = Product(id: 3, categoryId: 1, name: 'C', priceCents: 100, stock: 0);

      expect(inStock.isOutOfStock, isFalse);
      expect(inStock.isLowStock, isFalse);
      expect(low.isLowStock, isTrue);
      expect(low.isOutOfStock, isFalse);
      expect(out.isOutOfStock, isTrue);
      expect(out.isLowStock, isFalse);
    });

    test('copyWith preserves unspecified fields and can clear imagePath', () {
      const product = Product(
        id: 1,
        categoryId: 1,
        name: 'A',
        priceCents: 100,
        imagePath: 'images/a.jpg',
      );
      final renamed = product.copyWith(name: 'B');
      expect(renamed.name, 'B');
      expect(renamed.priceCents, 100);
      expect(renamed.imagePath, 'images/a.jpg');

      final cleared = product.copyWith(imagePath: null);
      expect(cleared.imagePath, isNull);
      expect(cleared.name, 'A');
    });

    test('value equality via Equatable', () {
      const a = Product(id: 1, categoryId: 1, name: 'A', priceCents: 100);
      const b = Product(id: 1, categoryId: 1, name: 'A', priceCents: 100);
      const c = Product(id: 2, categoryId: 1, name: 'A', priceCents: 100);
      expect(a, b);
      expect(a == c, isFalse);
    });
  });

  group('Category', () {
    test('copyWith updates the name and preserves the id', () {
      const cat = Category(id: 1, name: 'Clothing');
      expect(cat.copyWith(name: 'Shoes').name, 'Shoes');
      expect(cat.copyWith(name: 'Shoes').id, 1);
    });

    test('value equality', () {
      expect(const Category(id: 1, name: 'Clothing'), const Category(id: 1, name: 'Clothing'));
      expect(const Category(id: 1, name: 'Clothing') == const Category(id: 2, name: 'Clothing'), isFalse);
    });
  });

  group('CartItem', () {
    test('copyWith updates quantity only', () {
      const item = CartItem(productId: 5, quantity: 2);
      expect(item.copyWith(quantity: 3).quantity, 3);
      expect(item.copyWith(quantity: 3).productId, 5);
    });

    test('value equality via Equatable', () {
      const a = CartItem(productId: 5, quantity: 2);
      const b = CartItem(productId: 5, quantity: 2);
      const c = CartItem(productId: 5, quantity: 3);
      expect(a, b);
      expect(a == c, isFalse);
    });
  });

  group('ShippingInfo', () {
    test('isEmpty only when every field is blank', () {
      expect(const ShippingInfo().isEmpty, isTrue);
      expect(const ShippingInfo(name: 'a').isEmpty, isFalse);
      expect(const ShippingInfo(phone: '1').isEmpty, isFalse);
      expect(const ShippingInfo(address: 'x').isEmpty, isFalse);
    });

    test('copyWith replaces fields independently', () {
      const info = ShippingInfo(name: 'a', phone: '1', address: 'x');
      expect(info.copyWith(address: 'y').address, 'y');
      expect(info.copyWith(address: 'y').name, 'a');
      expect(info.copyWith(address: 'y').phone, '1');
    });
  });

  group('OrderItem', () {
    test('computes line totals from snapshot values', () {
      const item = OrderItem(
        orderId: 1,
        productName: 'T',
        unitPriceCents: 2000,
        discountPercent: 25,
        quantity: 3,
      );
      expect(item.unitFinalPriceCents, 1500);
      expect(item.lineTotalCents, 4500);
    });

    test('value equality includes all snapshot fields', () {
      const a = OrderItem(orderId: 1, productName: 'T', unitPriceCents: 2000, quantity: 1);
      const b = OrderItem(orderId: 1, productName: 'T', unitPriceCents: 2000, quantity: 1);
      const c = OrderItem(orderId: 1, productName: 'T', unitPriceCents: 2000, quantity: 2);
      expect(a, b);
      expect(a == c, isFalse);
    });
  });

  group('Order', () {
    test('carries snapshot totals and the status timeline', () {
      final placedAt = DateTime(2026, 8, 5, 12);
      final order = Order(
        id: 1,
        orderNumber: 'ORD-000001',
        status: OrderStatus.confirmed,
        subtotalCents: 6000,
        discountCents: 1500,
        totalCents: 4500,
        shipping: const ShippingInfo(name: 'Ada'),
        items: const [
          OrderItem(orderId: 1, productName: 'T', unitPriceCents: 2000, quantity: 3),
        ],
        statusHistory: [
          OrderStatusEntry(status: OrderStatus.pending, changedAt: placedAt),
        ],
        createdAt: placedAt,
      );

      expect(order.totalCents, 4500);
      expect(order.items, hasLength(1));
      expect(order.statusHistory, hasLength(1));
      expect(order.statusHistory.single.status, OrderStatus.pending);
      expect(order.statusHistory.single.changedAt, placedAt);
      expect(order.shipping.name, 'Ada');
    });

    test('value equality includes the timeline', () {
      final placedAt = DateTime(2026, 8, 5, 12);
      Order build() => Order(
            id: 1,
            orderNumber: 'ORD-000001',
            status: OrderStatus.pending,
            subtotalCents: 1000,
            discountCents: 0,
            totalCents: 1000,
            shipping: const ShippingInfo(name: 'Ada'),
            statusHistory: [
              OrderStatusEntry(status: OrderStatus.pending, changedAt: placedAt),
            ],
          );
      expect(build(), build());
    });
  });
}

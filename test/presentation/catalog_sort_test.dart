import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/presentation/features/catalog/catalog_sort.dart';

Product product(
  int id,
  String name, {
  int priceCents = 1000,
  int discountPercent = 0,
  DateTime? createdAt,
}) =>
    Product(
      id: id,
      categoryId: 1,
      name: name,
      priceCents: priceCents,
      discountPercent: discountPercent,
      createdAt: createdAt,
    );

List<Product> sorted(List<Product> products, CatalogSort sort) {
  final copy = List<Product>.of(products)..sort(sort.compare);
  return copy;
}

void main() {
  // A fixed base time; each product shifts by its id so ordering is obvious.
  final base = DateTime(2026, 7, 1);

  final products = [
    product(1, 'Beanie', priceCents: 1500, createdAt: base),
    product(2, 'Tee', priceCents: 2000, createdAt: base.add(const Duration(hours: 2))),
    product(3, 'Jacket', priceCents: 4500, createdAt: base.subtract(const Duration(hours: 1))),
  ];

  test('newest sorts by createdAt descending (default)', () {
    final result = sorted(products, CatalogSort.newest);
    expect(result.map((p) => p.id), [2, 1, 3]);
  });

  test('name sorts alphabetically, case-insensitively', () {
    final mixed = [
      ...products,
      product(4, 'belt', priceCents: 500),
    ];
    final result = sorted(mixed, CatalogSort.name);
    expect(result.map((p) => p.name), ['Beanie', 'belt', 'Jacket', 'Tee']);
  });

  test('priceAsc sorts by discounted (final) price, lowest first', () {
    final result = sorted(products, CatalogSort.priceAsc);
    expect(result.map((p) => p.id), [1, 2, 3]);
  });

  test('priceDesc sorts by discounted (final) price, highest first', () {
    final result = sorted(products, CatalogSort.priceDesc);
    expect(result.map((p) => p.id), [3, 2, 1]);
  });

  test('price sorting uses the final (discounted) price, not the base', () {
    final discounted = product(10, 'Cheap', priceCents: 10000, discountPercent: 90);
    final plain = product(11, 'Plain', priceCents: 800);
    // Discounted final price 1000 > plain 800.
    final result = sorted([discounted, plain], CatalogSort.priceAsc);
    expect(result.map((p) => p.id), [11, 10]);
  });

  test('name is the deterministic tiebreak for equal primary keys', () {
    final samePrice = [
      product(1, 'Zebra', priceCents: 1000, createdAt: base),
      product(2, 'Alpha', priceCents: 1000, createdAt: base),
      product(3, 'Mango', priceCents: 1000, createdAt: base),
    ];
    final result = sorted(samePrice, CatalogSort.priceAsc);
    expect(result.map((p) => p.name), ['Alpha', 'Mango', 'Zebra']);
  });

  test('a missing createdAt behaves as the epoch (oldest) under newest', () {
    final result = sorted(
      [
        product(1, 'NoDate', createdAt: null),
        product(2, 'Recent', createdAt: base),
      ],
      CatalogSort.newest,
    );
    expect(result.map((p) => p.name), ['Recent', 'NoDate']);
  });
}

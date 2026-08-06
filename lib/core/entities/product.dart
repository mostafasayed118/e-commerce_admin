import 'package:equatable/equatable.dart';

import '../utils/money.dart';

/// A sellable product. All money fields are integer cents (Decision C) and
/// the discounted price is derived, never stored.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.nameAr,
    this.descriptionAr,
    required this.priceCents,
    this.discountPercent = 0,
    this.stock = 0,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  /// Stock at or below which a product is flagged low-stock (admin alert).
  static const int lowStockThreshold = 5;

  final int id;
  final int categoryId;
  final String name;
  final String description;

  /// Optional Arabic label; `null` = English-only (the UI falls back to
  /// [name]). Canonical content stays [name]; this is the localized variant.
  final String? nameAr;
  final String? descriptionAr;

  /// Original price in cents.
  final int priceCents;

  /// Discount percentage, 0-100. The final price is derived, never stored.
  final int discountPercent;
  final int stock;

  /// Relative path to the stored image inside the app documents dir;
  /// `null` means the product has no image.
  final String? imagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasDiscount => discountPercent > 0;

  /// Price the customer actually pays, after discount (integer math).
  int get finalPriceCents => discountedPriceCents(priceCents, discountPercent);

  /// Amount saved by the discount, in cents.
  int get savingsCents => discountAmountCents(priceCents, discountPercent);

  bool get isOutOfStock => stock <= 0;

  /// Has stock left but at or below the alert threshold.
  bool get isLowStock => !isOutOfStock && stock <= lowStockThreshold;

  /// Sentinel so `copyWith(imagePath: null)` can *clear* the image —
  /// a plain `null ?? current` would be unable to distinguish "unchanged"
  /// from "set to null".
  static const Object _unset = Object();

  Product copyWith({
    int? categoryId,
    String? name,
    String? description,
    Object? nameAr = _unset,
    Object? descriptionAr = _unset,
    int? priceCents,
    int? discountPercent,
    int? stock,
    Object? imagePath = _unset,
    DateTime? updatedAt,
  }) {
    assert(
      identical(nameAr, _unset) || nameAr is String?,
      'nameAr must be a String? or omitted',
    );
    assert(
      identical(descriptionAr, _unset) || descriptionAr is String?,
      'descriptionAr must be a String? or omitted',
    );
    assert(
      identical(imagePath, _unset) || imagePath is String?,
      'imagePath must be a String? or omitted',
    );
    return Product(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      nameAr: identical(nameAr, _unset) ? this.nameAr : nameAr as String?,
      descriptionAr: identical(descriptionAr, _unset)
          ? this.descriptionAr
          : descriptionAr as String?,
      priceCents: priceCents ?? this.priceCents,
      discountPercent: discountPercent ?? this.discountPercent,
      stock: stock ?? this.stock,
      imagePath:
          identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        name,
        description,
        nameAr,
        descriptionAr,
        priceCents,
        discountPercent,
        stock,
        imagePath,
        createdAt,
        updatedAt,
      ];
}

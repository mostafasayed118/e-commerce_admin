import '../../../core/entities/product.dart';
// Row classes are generated in app_database.g.dart (part of app_database.dart).
import '../app_database.dart';

/// Converts between the drift row and the domain entity. Mapping belongs in
/// the data layer (Section C.1) — entities never see drift types and drift
/// rows never see entities.
class ProductMapper {
  Product toEntity(ProductRow row) => Product(
        id: row.id,
        categoryId: row.categoryId,
        name: row.name,
        description: row.description,
        priceCents: row.priceCents,
        discountPercent: row.discountPercent,
        stock: row.stock,
        imagePath: row.imagePath,
        createdAt: _fromEpoch(row.createdAt),
        updatedAt: _fromEpoch(row.updatedAt),
      );

  // Writes go through companions built in the repository (which owns
  // timestamps), so there is no entity -> row mapping here.

  DateTime? _fromEpoch(int? epochMs) =>
      epochMs == null ? null : DateTime.fromMillisecondsSinceEpoch(epochMs);
}

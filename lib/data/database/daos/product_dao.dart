import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'product_dao.g.dart';

/// Data access for products. Returns raw [ProductRow]s — mapping to domain
/// entities happens in the repository layer, so drift types never escape the
/// data layer.
@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.attachedDatabase);

  /// Reactive list of all products, ordered by name.
  Stream<List<ProductRow>> watchAll() {
    return (select(products)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Reactive single product; emits `null` when it is missing or deleted.
  Stream<ProductRow?> watchById(int id) {
    return (select(products)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<ProductRow?> getById(int id) {
    return (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Returns the new row id.
  Future<int> insert(ProductsCompanion companion) =>
      into(products).insert(companion);

  /// Applies only the non-absent fields of [companion]; returns affected rows.
  Future<int> updateById(int id, ProductsCompanion companion) {
    return (update(products)..where((t) => t.id.equals(id))).write(companion);
  }

  /// Returns the number of deleted rows.
  Future<int> deleteById(int id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }
}

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'int_id_crud_mixin.dart';

part 'product_dao.g.dart';

/// Data access for products. Returns raw [ProductRow]s — mapping to domain
/// entities happens in the repository layer, so drift types never escape the
/// data layer.
@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase>
    with
        _$ProductDaoMixin,
        IntIdCrudDaoMixin<$ProductsTable, ProductRow, ProductsCompanion> {
  ProductDao(super.attachedDatabase);

  @override
  $ProductsTable get table => products;

  @override
  GeneratedColumn<int> get idColumn => products.id;

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
}

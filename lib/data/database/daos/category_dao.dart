import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'category_dao.g.dart';

/// Data access for categories. Returns raw [CategoryRow]s; mapping to domain
/// entities happens in the repository layer.
@DriftAccessor(tables: [Categories, Products])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.attachedDatabase);

  /// Reactive list of all categories, ordered by name.
  Stream<List<CategoryRow>> watchAll() {
    return (select(categories)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<CategoryRow?> getById(int id) {
    return (select(categories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns the new row id.
  Future<int> insert(CategoriesCompanion companion) =>
      into(categories).insert(companion);

  /// Applies only the non-absent fields of [companion]; returns affected rows.
  Future<int> updateById(int id, CategoriesCompanion companion) {
    return (update(categories)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Returns the number of deleted rows.
  Future<int> deleteById(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  /// How many products reference [categoryId] — used to block deletion of a
  /// non-empty category (spec A4).
  Future<int> productCount(int categoryId) async {
    final rows = await (select(products)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
    return rows.length;
  }
}

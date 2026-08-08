import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'int_id_crud_mixin.dart';

part 'category_dao.g.dart';

/// Data access for categories. Returns raw [CategoryRow]s; mapping to domain
/// entities happens in the repository layer.
@DriftAccessor(tables: [Categories, Products])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with
        _$CategoryDaoMixin,
        IntIdCrudDaoMixin<$CategoriesTable, CategoryRow, CategoriesCompanion> {
  CategoryDao(super.attachedDatabase);

  @override
  $CategoriesTable get table => categories;

  @override
  GeneratedColumn<int> get idColumn => categories.id;

  /// Reactive list of all categories, ordered by name.
  Stream<List<CategoryRow>> watchAll() {
    return (select(categories)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
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

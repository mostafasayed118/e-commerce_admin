import 'package:drift/drift.dart';

import '../app_database.dart';

/// The by-integer-id CRUD shape shared by the id-keyed DAOs (Categories,
/// Products, Coupons): read-one-by-id, insert-returning-id, update-returning-
/// affected-rows, delete-returning-affected-rows.
///
/// Drift exposes no abstract "primary key column" on [TableInfo], so each
/// DAO supplies its table (via [table]) and its id column (via [idColumn]);
/// the four operations are then identical for every id-keyed table.
///
/// Deliberately NOT used by the cart/wishlist DAOs: their rows are keyed by
/// `productId` and their insert/delete return `void` (the caller never needs
/// the id — the productId is the caller's own input), so their shapes differ.
/// The order/settings DAOs are aggregate / single-row and have no shared
/// CRUD shape at all.
mixin IntIdCrudDaoMixin<
  T extends TableInfo<T, Row>,
  Row extends DataClass,
  Companion extends UpdateCompanion<Row>
>
    on DatabaseAccessor<AppDatabase> {
  /// The table this DAO serves (e.g. `categories`).
  T get table;

  /// The table's integer id column (e.g. `categories.id`).
  GeneratedColumn<int> get idColumn;

  /// The row with [id], or `null` when absent.
  Future<Row?> getById(int id) {
    // The predicate ignores its table argument — the id column comes from
    // [idColumn] (the same column, supplied by the concrete DAO).
    return (select(table)..where((_) => idColumn.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts [companion] and returns the new row id.
  Future<int> insert(Companion companion) => into(table).insert(companion);

  /// Applies only the non-absent fields of [companion] to the row with [id];
  /// returns affected rows (0 = no such row).
  Future<int> updateById(int id, Companion companion) {
    return (update(table)..where((_) => idColumn.equals(id)))
        .write(companion);
  }

  /// Deletes the row with [id]; returns affected rows (0 = no such row).
  Future<int> deleteById(int id) {
    return (delete(table)..where((_) => idColumn.equals(id))).go();
  }
}

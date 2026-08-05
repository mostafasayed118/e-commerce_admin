import '../../core/entities/category.dart';
import '../../core/error/result.dart';

/// Read/write access to categories.
abstract interface class CategoryRepository {
  /// Reactive list of all categories, ordered by name.
  Stream<List<Category>> watchCategories();

  Future<Result<Category>> getById(int id);

  /// Persists a new category; returns it with its generated id and timestamp.
  Future<Result<Category>> createCategory(Category category);

  Future<Result<Category>> updateCategory(Category category);

  /// Deletes the category. Blocked with a [ValidationError] while products
  /// reference it (spec A4); a missing category yields [NotFoundError].
  Future<Result<void>> deleteCategory(int id);
}

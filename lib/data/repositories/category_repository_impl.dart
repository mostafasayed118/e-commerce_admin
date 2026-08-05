import 'package:drift/drift.dart';

import '../../core/entities/category.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/category_repository.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/mappers/category_mapper.dart';

/// drift-backed [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dao, this._mapper);

  final CategoryDao _dao;
  final CategoryMapper _mapper;

  @override
  Stream<List<Category>> watchCategories() =>
      _dao.watchAll().map((rows) => rows.map(_mapper.toEntity).toList());

  @override
  Future<Result<Category>> getById(int id) async {
    try {
      final row = await _dao.getById(id);
      if (row == null) {
        return const Failure(NotFoundError(message: 'Category not found'));
      }
      return Success(_mapper.toEntity(row));
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not load category', cause: error),
      );
    }
  }

  @override
  Future<Result<Category>> createCategory(Category category) async {
    try {
      final now = DateTime.now();
      final id = await _dao.insert(CategoriesCompanion.insert(
            name: category.name,
            createdAt: now.millisecondsSinceEpoch,
          ));
      // Category.copyWith has no id parameter, so the entity is constructed
      // with the generated id explicitly.
      return Success(Category(id: id, name: category.name, createdAt: now));
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not create category', cause: error),
      );
    }
  }

  @override
  Future<Result<Category>> updateCategory(Category category) async {
    try {
      final updated = await _dao.updateById(
        category.id,
        CategoriesCompanion(name: Value(category.name)),
      );
      if (updated == 0) {
        return const Failure(NotFoundError(message: 'Category not found'));
      }
      return Success(category);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not update category', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> deleteCategory(int id) async {
    try {
      final productCount = await _dao.productCount(id);
      if (productCount > 0) {
        return Failure(ValidationError(
          message: 'Category has $productCount product(s); delete them first',
        ));
      }
      final deleted = await _dao.deleteById(id);
      if (deleted == 0) {
        return const Failure(NotFoundError(message: 'Category not found'));
      }
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not delete category', cause: error),
      );
    }
  }
}

import 'package:drift/drift.dart';

import '../../core/entities/category.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/category_repository.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/mappers/category_mapper.dart';
import '../guarded_result.dart';

/// drift-backed [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dao, this._mapper);

  final CategoryDao _dao;
  final CategoryMapper _mapper;

  @override
  Stream<List<Category>> watchCategories() =>
      _dao.watchAll().map((rows) => rows.map(_mapper.toEntity).toList());

  @override
  Future<Result<Category>> getById(int id) => guardedLoadById(
        () => _dao.getById(id),
        message: 'Could not load category',
        notFoundCode: AppErrorCode.categoryNotFound,
        notFoundMessage: 'Category not found',
        map: _mapper.toEntity,
      );

  @override
  Future<Result<Category>> createCategory(Category category) => guardedResult(
        () async {
          final now = DateTime.now();
          final id = await _dao.insert(CategoriesCompanion.insert(
            name: category.name,
            nameAr: Value(category.nameAr),
            createdAt: now.millisecondsSinceEpoch,
          ));
          // Category.copyWith has no id parameter, so the entity is constructed
          // with the generated id explicitly.
          return Success(
            Category(
              id: id,
              name: category.name,
              nameAr: category.nameAr,
              createdAt: now,
            ),
          );
        },
        message: 'Could not create category',
      );

  @override
  Future<Result<Category>> updateCategory(Category category) =>
      guardedAffectedRows(
        () => _dao.updateById(
          category.id,
          CategoriesCompanion(
            name: Value(category.name),
            nameAr: Value(category.nameAr),
          ),
        ),
        message: 'Could not update category',
        notFoundCode: AppErrorCode.categoryNotFound,
        notFoundMessage: 'Category not found',
        onAffected: () => category,
      );

  @override
  Future<Result<void>> deleteCategory(int id) => guardedResult(
        () async {
          final productCount = await _dao.productCount(id);
          if (productCount > 0) {
            return Failure(CategoryInUseError(
              productCount: productCount,
              message:
                  'Category has $productCount product(s); delete them first',
            ));
          }
          return guardedAffectedRows(
            () => _dao.deleteById(id),
            message: 'Could not delete category',
            notFoundCode: AppErrorCode.categoryNotFound,
            notFoundMessage: 'Category not found',
          );
        },
        message: 'Could not delete category',
      );
}

import 'package:drift/drift.dart';

import '../../core/entities/product.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/product_repository.dart';
import '../database/app_database.dart';
import '../database/daos/product_dao.dart';
import '../database/mappers/product_mapper.dart';

/// drift-backed [ProductRepository].
///
/// The error boundary (Section D.4): every one-shot operation wraps drift
/// exceptions in [Result] here — Cubits and widgets never see raw exceptions.
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._dao, this._mapper);

  final ProductDao _dao;
  final ProductMapper _mapper;

  @override
  Stream<List<Product>> watchProducts() =>
      _dao.watchAll().map((rows) => rows.map(_mapper.toEntity).toList());

  @override
  Stream<Product?> watchProductById(int id) =>
      _dao.watchById(id).map((row) => row == null ? null : _mapper.toEntity(row));

  @override
  Future<Result<Product>> getById(int id) async {
    try {
      final row = await _dao.getById(id);
      if (row == null) {
        return const Failure(NotFoundError(
          code: AppErrorCode.productNotFound,
          message: 'Product not found',
        ));
      }
      return Success(_mapper.toEntity(row));
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not load product', cause: error),
      );
    }
  }

  @override
  Future<Result<Product>> createProduct(Product product) async {
    try {
      final now = DateTime.now();
      final id = await _dao.insert(ProductsCompanion.insert(
            categoryId: product.categoryId,
            name: product.name,
            description: Value(product.description),
            nameAr: Value(product.nameAr),
            descriptionAr: Value(product.descriptionAr),
            priceCents: product.priceCents,
            discountPercent: product.discountPercent,
            stock: product.stock,
            imagePath: Value(product.imagePath),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ));
      // Product.copyWith deliberately cannot change identity (id), so the
      // persisted entity is constructed explicitly with the generated id.
      return Success(Product(
        id: id,
        categoryId: product.categoryId,
        name: product.name,
        description: product.description,
        nameAr: product.nameAr,
        descriptionAr: product.descriptionAr,
        priceCents: product.priceCents,
        discountPercent: product.discountPercent,
        stock: product.stock,
        imagePath: product.imagePath,
        createdAt: now,
        updatedAt: now,
      ));
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not create product', cause: error),
      );
    }
  }

  @override
  Future<Result<Product>> updateProduct(Product product) async {
    try {
      final now = DateTime.now();
      final updated = await _dao.updateById(
        product.id,
        ProductsCompanion(
          categoryId: Value(product.categoryId),
          name: Value(product.name),
          description: Value(product.description),
          nameAr: Value(product.nameAr),
          descriptionAr: Value(product.descriptionAr),
          priceCents: Value(product.priceCents),
          discountPercent: Value(product.discountPercent),
          stock: Value(product.stock),
          imagePath: Value(product.imagePath),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (updated == 0) {
        return const Failure(NotFoundError(
          code: AppErrorCode.productNotFound,
          message: 'Product not found',
        ));
      }
      return Success(product.copyWith(updatedAt: now));
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not update product', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> deleteProduct(int id) async {
    try {
      final deleted = await _dao.deleteById(id);
      if (deleted == 0) {
        return const Failure(NotFoundError(
          code: AppErrorCode.productNotFound,
          message: 'Product not found',
        ));
      }
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not delete product', cause: error),
      );
    }
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/category.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/error/result.dart';
import '../../../../data/services/image_store.dart';
import '../../../../domain/repositories/category_repository.dart';
import '../../../../domain/repositories/product_repository.dart';
import 'admin_catalog_state.dart';

export 'admin_catalog_state.dart';

/// Drives the admin products + categories screens. Same manual two-stream
/// combine as CatalogCubit; CRUD actions delegate to the repositories (which
/// own the Result boundary) and return the Result so screens can pop on
/// success / show the error on failure. The watch streams then re-emit the
/// updated list automatically.
class AdminCatalogCubit extends Cubit<AdminCatalogState> {
  AdminCatalogCubit(this._products, this._categories, this._images)
      : super(const AdminCatalogLoading()) {
    _subscribe();
  }

  final ProductRepository _products;
  final CategoryRepository _categories;
  final ImageStore _images;

  List<Product>? _allProducts;
  List<Category>? _allCategories;
  bool _failed = false;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<Category>>? _categoriesSub;

  void _subscribe() {
    _productsSub = _products.watchProducts().listen(
      (products) {
        _allProducts = products;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const AdminCatalogError('Could not load products'));
      },
    );
    _categoriesSub = _categories.watchCategories().listen(
      (categories) {
        _allCategories = categories;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const AdminCatalogError('Could not load categories'));
      },
    );
  }

  void _recompute() {
    if (_failed) return; // sticky error, as in CatalogCubit
    final products = _allProducts;
    final categories = _allCategories;
    if (products == null || categories == null) return;
    emit(AdminCatalogLoaded(products: products, categories: categories));
  }

  // --- Product CRUD --------------------------------------------------------

  Future<Result<Product>> createProduct(Product draft) =>
      _products.createProduct(draft);

  Future<Result<Product>> updateProduct(Product product) =>
      _products.updateProduct(product);

  Future<Result<void>> deleteProduct(int id) async {
    final result = await _products.deleteProduct(id);
    if (result.isSuccess) {
      // Best-effort file cleanup: remove the stored image so a deleted
      // product leaves no orphan file. Missing file = Success (see ImageStore).
      final imagePath =
          _allProducts?.where((p) => p.id == id).firstOrNull?.imagePath;
      if (imagePath != null) {
        await _images.deleteImage(imagePath);
      }
    }
    return result;
  }

  // --- Category CRUD -------------------------------------------------------

  Future<Result<Category>> createCategory(String name, {String? nameAr}) =>
      _categories.createCategory(Category(id: 0, name: name, nameAr: nameAr));

  Future<Result<Category>> updateCategory(Category category) =>
      _categories.updateCategory(category);

  /// Blocked with a ValidationError while products reference the category
  /// (the data layer's delete-blocked rule, spec A4).
  Future<Result<void>> deleteCategory(int id) => _categories.deleteCategory(id);

  @override
  Future<void> close() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    return super.close();
  }
}

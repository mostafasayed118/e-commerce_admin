import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/category.dart';
import '../../../core/entities/product.dart';
import '../../../core/utils/search_text.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import 'catalog_sort.dart';
import 'catalog_state.dart';

export 'catalog_state.dart';

/// Drives the customer catalog: combines the product and category watch
/// streams (manual — no rxdart dependency), applies the current filter, query
/// and sort, and re-emits whenever any of them change.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._products, this._categories) : super(const CatalogLoading()) {
    _subscribe();
  }

  final ProductRepository _products;
  final CategoryRepository _categories;

  // Latest values from each stream; null until that stream first emits.
  List<Product>? _allProducts;
  List<Category>? _allCategories;

  int? _selectedCategoryId;
  String _query = '';
  CatalogSort _sort = CatalogSort.newest;

  /// Once a stream has failed, the error state is **sticky**: recompute is
  /// suppressed so a later emission from the other stream (or a user action)
  /// cannot silently resurrect content after an error. Deliberate — error is
  /// terminal until the cubit is recreated.
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
        emit(const CatalogError('Could not load products'));
      },
    );
    _categoriesSub = _categories.watchCategories().listen(
      (categories) {
        _allCategories = categories;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const CatalogError('Could not load categories'));
      },
    );
  }

  void selectCategory(int? id) {
    if (_selectedCategoryId == id) return;
    _selectedCategoryId = id;
    _recompute();
  }

  void setQuery(String query) {
    _query = query;
    _recompute();
  }

  void setSort(CatalogSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    _recompute();
  }

  void _recompute() {
    if (_failed) return; // error is terminal (sticky)
    final all = _allProducts;
    final categories = _allCategories;
    // Wait for BOTH streams to emit before the first loaded state.
    if (all == null || categories == null) return;

    if (all.isEmpty) {
      emit(const CatalogEmpty());
      return;
    }

    final query = normalizeSearchText(_query.trim());
    final filtered = all.where((product) {
      final inCategory =
          _selectedCategoryId == null || product.categoryId == _selectedCategoryId;
      // Matches against BOTH languages (each normalized the same way as the
      // query) so an Arabic shopper can search in Arabic while the canonical
      // text stays searchable in English.
      final matchesQuery = query.isEmpty ||
          normalizeSearchText(product.name).contains(query) ||
          normalizeSearchText(product.description).contains(query) ||
          (product.nameAr != null &&
              normalizeSearchText(product.nameAr!).contains(query)) ||
          (product.descriptionAr != null &&
              normalizeSearchText(product.descriptionAr!).contains(query));
      return inCategory && matchesQuery;
    }).toList()
      ..sort(_sort.compare);

    emit(CatalogLoaded(
      products: filtered,
      categories: categories,
      selectedCategoryId: _selectedCategoryId,
      query: _query,
      sort: _sort,
    ));
  }

  @override
  Future<void> close() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    return super.close();
  }
}

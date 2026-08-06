import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/category.dart';
import '../../../core/entities/product.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import 'catalog_sort.dart';

/// Sealed catalog states (Dart 3 + Equatable, no freezed).
sealed class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

/// Before the first emission from both watch streams.
final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

/// Products and categories are loaded; [products] is already filtered and
/// sorted by the current [selectedCategoryId], [query] and [sort]. An empty
/// [products] with an active filter means "no matches" — distinct from the
/// whole catalog being empty.
final class CatalogLoaded extends CatalogState {
  const CatalogLoaded({
    required this.products,
    required this.categories,
    this.selectedCategoryId,
    this.query = '',
    this.sort = CatalogSort.newest,
  });

  final List<Product> products;
  final List<Category> categories;

  /// `null` means "all categories".
  final int? selectedCategoryId;
  final String query;
  final CatalogSort sort;

  bool get hasActiveFilter =>
      selectedCategoryId != null || query.trim().isNotEmpty;

  @override
  List<Object?> get props =>
      [products, categories, selectedCategoryId, query, sort];
}

/// No products exist at all (fresh database). Filtering out everything is a
/// separate case: see [CatalogLoaded.hasActiveFilter].
final class CatalogEmpty extends CatalogState {
  const CatalogEmpty();
}

final class CatalogError extends CatalogState {
  const CatalogError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

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

    final query = _query.trim().toLowerCase();
    final filtered = all.where((product) {
      final inCategory =
          _selectedCategoryId == null || product.categoryId == _selectedCategoryId;
      // Matches against BOTH languages so an Arabic shopper can search in
      // Arabic while the canonical text stays searchable in English.
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          (product.nameAr?.toLowerCase().contains(query) ?? false) ||
          (product.descriptionAr?.toLowerCase().contains(query) ?? false);
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

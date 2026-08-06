import 'package:equatable/equatable.dart';

import '../../../core/entities/category.dart';
import '../../../core/entities/product.dart';
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

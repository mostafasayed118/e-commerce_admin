import 'package:equatable/equatable.dart';

import '../../../../core/entities/category.dart';
import '../../../../core/entities/product.dart';

/// Sealed admin catalog states.
sealed class AdminCatalogState extends Equatable {
  const AdminCatalogState();

  @override
  List<Object?> get props => [];
}

final class AdminCatalogLoading extends AdminCatalogState {
  const AdminCatalogLoading();
}

/// Both datasets loaded. An empty [products] is the normal fresh-install
/// state — the screen renders an empty view with the create action.
final class AdminCatalogLoaded extends AdminCatalogState {
  const AdminCatalogLoaded({required this.products, required this.categories});

  final List<Product> products;
  final List<Category> categories;

  @override
  List<Object?> get props => [products, categories];
}

final class AdminCatalogError extends AdminCatalogState {
  const AdminCatalogError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

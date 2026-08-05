import '../../core/entities/product.dart';
import '../../core/error/result.dart';

/// Read/write access to products.
///
/// One-shot operations return [Result] — errors are caught at the repository
/// boundary (Section D.4), never in Cubits or widgets. Watch streams carry
/// plain data and surface database errors as stream errors for the consumer
/// to handle.
abstract interface class ProductRepository {
  /// Reactive list of all products, ordered by name.
  Stream<List<Product>> watchProducts();

  /// Reactive single product; emits `null` when missing or deleted.
  Stream<Product?> watchProductById(int id);

  Future<Result<Product>> getById(int id);

  /// Persists a new product; returns it with its generated id and timestamps.
  Future<Result<Product>> createProduct(Product product);

  /// Persists changes; returns the product with a fresh [Product.updatedAt].
  Future<Result<Product>> updateProduct(Product product);

  /// Deletes the product. Success even when it never existed is NOT implied —
  /// a missing product yields [NotFoundError].
  Future<Result<void>> deleteProduct(int id);
}

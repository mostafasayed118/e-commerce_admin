import 'package:get_it/get_it.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/product_dao.dart';
import '../../data/database/mappers/category_mapper.dart';
import '../../data/database/mappers/product_mapper.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/product_repository.dart';

/// The composition root: the one place that may touch every layer. Manual
/// registration, no codegen (Section B.3). Feature tasks extend this as they
/// introduce Cubits and use cases (Task 12 adds the app shell).
///
/// NOTE: this is a deliberate exception to the core -> domain -> data
/// dependency direction — a composition root by definition wires everything
/// together. All other core/ files stay layer-pure.
final getIt = GetIt.instance;

void setupDependencies() {
  // Data layer.
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  getIt.registerLazySingleton<ProductDao>(() => ProductDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<CategoryDao>(() => CategoryDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<ProductMapper>(ProductMapper.new);
  getIt.registerLazySingleton<CategoryMapper>(CategoryMapper.new);

  // Domain interfaces → data implementations.
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
    getIt<ProductDao>(),
    getIt<ProductMapper>(),
  ));
  getIt.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(
    getIt<CategoryDao>(),
    getIt<CategoryMapper>(),
  ));
}

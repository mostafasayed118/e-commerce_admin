import 'package:get_it/get_it.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/cart_dao.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/order_dao.dart';
import '../../data/database/daos/product_dao.dart';
import '../../data/database/daos/settings_dao.dart';
import '../../data/database/mappers/category_mapper.dart';
import '../../data/database/mappers/order_mapper.dart';
import '../../data/database/mappers/product_mapper.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/cart/add_to_cart.dart';
import '../../domain/usecases/cart/clear_cart.dart';
import '../../domain/usecases/cart/remove_from_cart.dart';
import '../../domain/usecases/cart/update_cart_quantity.dart';

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
  getIt.registerLazySingleton<CartDao>(() => CartDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<OrderDao>(() => OrderDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<SettingsDao>(
    () => SettingsDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ProductMapper>(ProductMapper.new);
  getIt.registerLazySingleton<CategoryMapper>(CategoryMapper.new);
  getIt.registerLazySingleton<OrderMapper>(OrderMapper.new);

  // Domain interfaces → data implementations.
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
    getIt<ProductDao>(),
    getIt<ProductMapper>(),
  ));
  getIt.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(
    getIt<CategoryDao>(),
    getIt<CategoryMapper>(),
  ));
  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(getIt<CartDao>()),
  );
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(
    getIt<OrderDao>(),
    getIt<ProductDao>(),
    getIt<CartDao>(),
    getIt<ProductMapper>(),
    getIt<OrderMapper>(),
    getIt<AppDatabase>(),
  ));
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(getIt<SettingsDao>()),
  );

  // Domain use cases (Decision A): cart business rules live here; the
  // repositories stay dumb storage gates.
  getIt.registerLazySingleton<AddToCart>(() => AddToCart(
    getIt<CartRepository>(),
    getIt<ProductRepository>(),
  ));
  getIt.registerLazySingleton<UpdateCartQuantity>(() => UpdateCartQuantity(
    getIt<CartRepository>(),
    getIt<ProductRepository>(),
  ));
  getIt.registerLazySingleton<RemoveFromCart>(
    () => RemoveFromCart(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<ClearCart>(
    () => ClearCart(getIt<CartRepository>()),
  );
}

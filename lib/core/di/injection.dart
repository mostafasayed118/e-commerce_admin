import 'package:get_it/get_it.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/cart_dao.dart';
import '../../data/database/seed_data.dart';
import '../../data/database/daos/wishlist_dao.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/coupon_dao.dart';
import '../../data/database/daos/order_dao.dart';
import '../../data/database/daos/review_dao.dart';
import '../../data/database/daos/product_dao.dart';
import '../../data/database/daos/settings_dao.dart';
import '../../data/database/mappers/category_mapper.dart';
import '../../data/database/mappers/coupon_mapper.dart';
import '../../data/database/mappers/review_mapper.dart';
import '../../data/services/image_store.dart';
import '../../data/database/mappers/order_mapper.dart';
import '../../data/database/mappers/product_mapper.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/repositories/coupon_repository_impl.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/repositories/wishlist_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/cart/add_to_cart.dart';
import '../../domain/usecases/cart/clear_cart.dart';
import '../../domain/usecases/cart/remove_from_cart.dart';
import '../../domain/usecases/cart/update_cart_quantity.dart';
import '../../domain/usecases/wishlist/add_all_wishlist_to_cart.dart';
import '../../domain/usecases/wishlist/move_wishlist_item_to_cart.dart';
import '../../domain/usecases/wishlist/toggle_wishlist.dart';
import '../../domain/usecases/checkout/place_order.dart';
import '../../domain/usecases/coupons/apply_coupon.dart';
import '../../domain/usecases/profile/save_profile.dart';
import '../../domain/usecases/reviews/add_review.dart';
import '../../presentation/features/admin/catalog/admin_catalog_cubit.dart';
import '../../presentation/features/admin/orders/admin_orders_cubit.dart';
import '../../presentation/features/admin/overview/admin_overview_cubit.dart';
import '../../presentation/features/cart/cart_cubit.dart';
import '../../presentation/features/catalog/catalog_cubit.dart';
import '../../presentation/features/wishlist/wishlist_cubit.dart';
import '../../presentation/features/admin/coupons/admin_coupons_cubit.dart';
import '../../presentation/features/admin/reviews/admin_reviews_cubit.dart';
import '../../presentation/features/orders/orders_cubit.dart';
import '../../presentation/features/profile/profile_cubit.dart';
import '../../presentation/locale/locale_cubit.dart';
import '../../presentation/theme/theme_cubit.dart';
import '../../presentation/router/admin_session.dart';

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
  getIt.registerLazySingleton<SeedData>(() => SeedData(getIt<AppDatabase>()));
  getIt.registerLazySingleton<ProductDao>(() => ProductDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<CategoryDao>(() => CategoryDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<CouponDao>(() => CouponDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<ReviewDao>(() => ReviewDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<CartDao>(() => CartDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<WishlistDao>(
    () => WishlistDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<OrderDao>(() => OrderDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<SettingsDao>(
    () => SettingsDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ProductMapper>(ProductMapper.new);
  getIt.registerLazySingleton<CategoryMapper>(CategoryMapper.new);
  getIt.registerLazySingleton<CouponMapper>(CouponMapper.new);
  getIt.registerLazySingleton<ReviewMapper>(ReviewMapper.new);
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
  getIt.registerLazySingleton<CouponRepository>(
    () => CouponRepositoryImpl(
      getIt<CouponDao>(),
      getIt<CouponMapper>(),
    ),
  );
  getIt.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(
      getIt<ReviewDao>(),
      getIt<ReviewMapper>(),
    ),
  );
  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(getIt<CartDao>()),
  );
  getIt.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(getIt<WishlistDao>()),
  );
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(
    getIt<OrderDao>(),
    getIt<ProductDao>(),
    getIt<CartDao>(),
    getIt<CouponDao>(),
    getIt<ProductMapper>(),
    getIt<OrderMapper>(),
    getIt<CouponMapper>(),
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
  getIt.registerLazySingleton<ToggleWishlist>(
    () => ToggleWishlist(getIt<WishlistRepository>()),
  );
  getIt.registerLazySingleton<MoveWishlistItemToCart>(() =>
      MoveWishlistItemToCart(
        getIt<AddToCart>(),
        getIt<WishlistRepository>(),
      ));
  getIt.registerLazySingleton<AddAllWishlistToCart>(() =>
      AddAllWishlistToCart(
        getIt<MoveWishlistItemToCart>(),
        getIt<WishlistRepository>(),
      ));
  getIt.registerLazySingleton<PlaceOrder>(() => PlaceOrder(
    getIt<OrderRepository>(),
    getIt<SettingsRepository>(),
  ));
  getIt.registerLazySingleton<ApplyCoupon>(
    () => ApplyCoupon(getIt<CouponRepository>()),
  );
  getIt.registerLazySingleton<AddReview>(
    () => AddReview(getIt<ReviewRepository>()),
  );
  getIt.registerLazySingleton<SaveProfile>(
    () => SaveProfile(getIt<SettingsRepository>()),
  );

  // App shell: the admin unlock flag consulted by the router guard.
  getIt.registerLazySingleton<AdminSession>(AdminSession.new);

  // Product images (Task 14): resolves the documents dir, copies picks into
  // images/, deletes on product deletion.
  getIt.registerLazySingleton<ImageStore>(ImageStore.new);

  // Features: one Cubit per feature, injected with its repositories.
  getIt.registerLazySingleton<CatalogCubit>(() => CatalogCubit(
    getIt<ProductRepository>(),
    getIt<CategoryRepository>(),
  ));
  getIt.registerLazySingleton<AdminCatalogCubit>(() => AdminCatalogCubit(
    getIt<ProductRepository>(),
    getIt<CategoryRepository>(),
    getIt<ImageStore>(),
  ));
  getIt.registerLazySingleton<CartCubit>(() => CartCubit(
    getIt<CartRepository>(),
    getIt<ProductRepository>(),
    getIt<UpdateCartQuantity>(),
    getIt<RemoveFromCart>(),
    getIt<ClearCart>(),
  ));
  getIt.registerLazySingleton<WishlistCubit>(() => WishlistCubit(
    getIt<WishlistRepository>(),
    getIt<ProductRepository>(),
    getIt<ToggleWishlist>(),
  ));
  getIt.registerLazySingleton<OrdersCubit>(
    () => OrdersCubit(getIt<OrderRepository>()),
  );
  getIt.registerLazySingleton<AdminOrdersCubit>(
    () => AdminOrdersCubit(getIt<OrderRepository>()),
  );
  getIt.registerLazySingleton<AdminOverviewCubit>(() => AdminOverviewCubit(
    getIt<OrderRepository>(),
    getIt<ProductRepository>(),
    getIt<CouponRepository>(),
  ));
  getIt.registerLazySingleton<AdminCouponsCubit>(
    () => AdminCouponsCubit(getIt<CouponRepository>()),
  );
  getIt.registerLazySingleton<AdminReviewsCubit>(
    () => AdminReviewsCubit(getIt<ReviewRepository>()),
  );
  getIt.registerLazySingleton<ProfileCubit>(() => ProfileCubit(
    getIt<SettingsRepository>(),
    getIt<SaveProfile>(),
  ));

  // App-level settings cubits (persisted via UiPrefs): theme + locale. Both
  // restore from the DB on construction, so DI singletons are the single
  // source of truth consumed by app.dart and the Profile switches.
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<LocaleCubit>(
    () => LocaleCubit(getIt<SettingsRepository>()),
  );
}

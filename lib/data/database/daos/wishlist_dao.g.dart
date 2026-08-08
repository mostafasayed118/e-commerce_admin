// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_dao.dart';

// ignore_for_file: type=lint
mixin _$WishlistDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $WishlistItemsTable get wishlistItems => attachedDatabase.wishlistItems;
  WishlistDaoManager get managers => WishlistDaoManager(this);
}

class WishlistDaoManager {
  final _$WishlistDaoMixin _db;
  WishlistDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$WishlistItemsTableTableManager get wishlistItems =>
      $$WishlistItemsTableTableManager(_db.attachedDatabase, _db.wishlistItems);
}

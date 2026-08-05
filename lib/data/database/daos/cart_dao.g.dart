// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_dao.dart';

// ignore_for_file: type=lint
mixin _$CartDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $CartItemsTable get cartItems => attachedDatabase.cartItems;
  CartDaoManager get managers => CartDaoManager(this);
}

class CartDaoManager {
  final _$CartDaoMixin _db;
  CartDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$CartItemsTableTableManager get cartItems =>
      $$CartItemsTableTableManager(_db.attachedDatabase, _db.cartItems);
}

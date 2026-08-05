// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dao.dart';

// ignore_for_file: type=lint
mixin _$OrderDaoMixin on DatabaseAccessor<AppDatabase> {
  $OrdersTable get orders => attachedDatabase.orders;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $OrderItemsTable get orderItems => attachedDatabase.orderItems;
  $OrderStatusHistoryTable get orderStatusHistory =>
      attachedDatabase.orderStatusHistory;
  OrderDaoManager get managers => OrderDaoManager(this);
}

class OrderDaoManager {
  final _$OrderDaoMixin _db;
  OrderDaoManager(this._db);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db.attachedDatabase, _db.orders);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db.attachedDatabase, _db.orderItems);
  $$OrderStatusHistoryTableTableManager get orderStatusHistory =>
      $$OrderStatusHistoryTableTableManager(
        _db.attachedDatabase,
        _db.orderStatusHistory,
      );
}

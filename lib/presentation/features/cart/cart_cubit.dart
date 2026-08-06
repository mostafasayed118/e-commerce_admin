import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/cart_item.dart';
import '../../../core/entities/product.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/usecases/cart/clear_cart.dart';
import '../../../domain/usecases/cart/remove_from_cart.dart';
import '../../../domain/usecases/cart/update_cart_quantity.dart';
import 'cart_state.dart';

export 'cart_state.dart';

/// Drives the cart screen and the shell's count badge. Same manual
/// two-stream combine as the other feature cubits: cart items + products
/// joined in memory, recomputed on every emission.
///
/// Mutations delegate to the use cases (Decision A — the stock cap lives in
/// UpdateCartQuantity) and return their [Result] so the screen shows a
/// SnackBar on failure; the watch streams then re-emit the new cart.
class CartCubit extends Cubit<CartState> {
  CartCubit(
    this._cart,
    this._products,
    this._updateQuantity,
    this._remove,
    this._clear,
  ) : super(const CartLoading()) {
    _subscribe();
  }

  final CartRepository _cart;
  final ProductRepository _products;
  final UpdateCartQuantity _updateQuantity;
  final RemoveFromCart _remove;
  final ClearCart _clear;

  List<CartItem>? _allItems;
  List<Product>? _allProducts;
  bool _failed = false;

  StreamSubscription<List<CartItem>>? _itemsSub;
  StreamSubscription<List<Product>>? _productsSub;

  void _subscribe() {
    _itemsSub = _cart.watchCart().listen(
      (items) {
        _allItems = items;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const CartError('Could not load your cart'));
      },
    );
    _productsSub = _products.watchProducts().listen(
      (products) {
        _allProducts = products;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const CartError('Could not load products'));
      },
    );
  }

  void _recompute() {
    if (_failed) return; // sticky error, as in the other feature cubits
    final items = _allItems;
    final products = _allProducts;
    if (items == null || products == null) return;

    final byId = {for (final product in products) product.id: product};
    final lines = <CartLine>[];
    for (final item in items) {
      final product = byId[item.productId];
      if (product == null) continue; // deleted product — skip the orphan row
      lines.add(CartLine(product: product, quantity: item.quantity));
    }

    var subtotal = 0;
    var discount = 0;
    var count = 0;
    for (final line in lines) {
      subtotal += line.lineSubtotalCents;
      discount += line.lineDiscountCents;
      count += line.quantity;
    }
    emit(CartLoaded(
      lines: lines,
      subtotalCents: subtotal,
      discountCents: discount,
      totalCents: subtotal - discount,
      itemCount: count,
    ));
  }

  // --- Actions: delegate to the use cases; Results feed the UI's SnackBars.

  Future<Result<void>> updateQuantity(int productId, int quantity) =>
      _updateQuantity(productId, quantity);

  Future<Result<void>> removeItem(int productId) => _remove(productId);

  Future<Result<void>> clear() => _clear();

  @override
  Future<void> close() {
    _itemsSub?.cancel();
    _productsSub?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/product.dart';
import '../../../core/entities/wishlist_item.dart';
import '../../../core/error/result.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/wishlist_repository.dart';
import '../../../domain/usecases/wishlist/toggle_wishlist.dart';
import 'wishlist_state.dart';

export 'wishlist_state.dart';

/// Drives the wishlist screen and the shell's count badge. The same manual
/// two-stream combine as the other feature cubits: wishlist rows + products
/// joined in memory, recomputed on every emission.
///
/// Mutations delegate to [ToggleWishlist] (the single business rule) and
/// return its [Result] so the UI can show a SnackBar on failure; the watch
/// streams then re-emit the new wishlist.
class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit(
    this._wishlist,
    this._products,
    this._toggle,
  ) : super(const WishlistLoading()) {
    _subscribe();
  }

  final WishlistRepository _wishlist;
  final ProductRepository _products;
  final ToggleWishlist _toggle;

  List<WishlistItem>? _allItems;
  List<Product>? _allProducts;
  bool _failed = false;

  StreamSubscription<List<WishlistItem>>? _itemsSub;
  StreamSubscription<List<Product>>? _productsSub;

  void _subscribe() {
    _itemsSub = _wishlist.watchWishlist().listen(
      (items) {
        _allItems = items;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const WishlistError('Could not load your wishlist'));
      },
    );
    _productsSub = _products.watchProducts().listen(
      (products) {
        _allProducts = products;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const WishlistError('Could not load products'));
      },
    );
  }

  void _recompute() {
    if (_failed) return; // sticky error, as in the other feature cubits
    final items = _allItems;
    final products = _allProducts;
    if (items == null || products == null) return;

    final byId = {for (final product in products) product.id: product};
    final lines = <WishlistLine>[];
    for (final item in items) {
      final product = byId[item.productId];
      if (product == null) continue; // deleted product — skip the orphan row
      lines.add(WishlistLine(product: product));
    }

    emit(WishlistLoaded(lines: lines, itemCount: lines.length));
  }

  // --- Actions: delegate to the use case; the Result feeds the UI's SnackBar.
  // The bool tells the caller whether the product ended up saved (true =
  // added, false = removed), so the UI never guesses the message.
  Future<Result<bool>> toggle(int productId) => _toggle(productId);

  @override
  Future<void> close() {
    _itemsSub?.cancel();
    _productsSub?.cancel();
    return super.close();
  }
}

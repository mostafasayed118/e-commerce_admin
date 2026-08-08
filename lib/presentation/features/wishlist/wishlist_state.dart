import 'package:equatable/equatable.dart';

import '../../../core/entities/product.dart';

/// A wishlist line: the saved product (joined *live* from the products watch
/// stream, so an admin's price or stock edit reflects immediately — same as
/// [CartLine]).
class WishlistLine extends Equatable {
  const WishlistLine({required this.product});

  final Product product;

  @override
  List<Object?> get props => [product];
}

/// Sealed wishlist states.
sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

final class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

final class WishlistError extends WishlistState {
  const WishlistError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Saved products in save order. An empty [lines] list is the normal fresh
/// state — the screen renders the empty view, not an error.
final class WishlistLoaded extends WishlistState {
  const WishlistLoaded({required this.lines, required this.itemCount});

  final List<WishlistLine> lines;

  /// The shell badge shows this.
  final int itemCount;

  @override
  List<Object?> get props => [lines, itemCount];
}

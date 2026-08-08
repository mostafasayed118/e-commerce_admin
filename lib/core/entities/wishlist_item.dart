import 'package:equatable/equatable.dart';

/// A saved product in the wishlist: one row per product, keyed by [productId].
///
/// Product details are joined in the data/presentation layers — this entity
/// only carries identity + save time so it stays a thin value object (same
/// shape as [CartItem], minus quantity).
class WishlistItem extends Equatable {
  const WishlistItem({required this.productId, this.addedAt});

  final int productId;
  final DateTime? addedAt;

  @override
  List<Object?> get props => [productId, addedAt];
}

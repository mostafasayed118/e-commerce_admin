/// Route names — used by navigation code instead of string literals so a
/// rename fails at compile time, not in a redirect.
abstract final class RouteNames {
  // Shop shell branches.
  static const String shop = 'shop';
  static const String cart = 'cart';
  static const String orders = 'orders';
  static const String profile = 'profile';
  // Top-level shop pages (above the shell).
  static const String productDetail = 'product-detail';
  static const String checkout = 'checkout';
  static const String orderDetail = 'order-detail';
  // Admin.
  static const String adminGate = 'admin-gate';
  static const String adminOverview = 'admin-overview';
  static const String adminProducts = 'admin-products';
  static const String adminProductNew = 'admin-product-new';
  static const String adminProductEdit = 'admin-product-edit';
  static const String adminCategories = 'admin-categories';
  static const String adminOrders = 'admin-orders';
  static const String adminOrderDetail = 'admin-order-detail';
}

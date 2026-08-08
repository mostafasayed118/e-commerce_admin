// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get backToStore => 'Back to store';

  @override
  String get create => 'Create';

  @override
  String get all => 'All';

  @override
  String get tabShop => 'Shop';

  @override
  String get tabWishlist => 'Wishlist';

  @override
  String get tabCart => 'Cart';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabProducts => 'Products';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabCoupons => 'Coupons';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusShipped => 'Shipped';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortName => 'Name A-Z';

  @override
  String get sortPriceAsc => 'Price: low to high';

  @override
  String get sortPriceDesc => 'Price: high to low';

  @override
  String get shopTitle => 'Shop';

  @override
  String get catalogEmptyTitle => 'The catalog is empty';

  @override
  String get catalogEmptyMessage =>
      'Products will appear here once they exist.';

  @override
  String get searchProducts => 'Search products';

  @override
  String productCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String get noMatches => 'No matches';

  @override
  String get noMatchesMessage =>
      'Nothing matches your current search or filter.';

  @override
  String get noProductsInCategory => 'No products in this category yet.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String lowStockLeft(int stock) {
    return 'Low stock: $stock left';
  }

  @override
  String get productTitle => 'Product';

  @override
  String get couldNotLoadProduct => 'Could not load product';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get productRemovedFromCatalog => 'This product may have been deleted.';

  @override
  String get inStock => 'In stock';

  @override
  String get noDescription => 'No description available.';

  @override
  String get adding => 'Adding…';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String addedToCart(String product) {
    return '$product added to cart';
  }

  @override
  String get wishlistTitle => 'Wishlist';

  @override
  String get wishlistEmptyTitle => 'Your wishlist is empty';

  @override
  String get wishlistEmptyMessage =>
      'Tap the heart on any product to save it for later.';

  @override
  String get addToWishlist => 'Add to wishlist';

  @override
  String get removeFromWishlist => 'Remove from wishlist';

  @override
  String addedToWishlist(String product) {
    return '$product added to wishlist';
  }

  @override
  String removedFromWishlist(String product) {
    return '$product removed from wishlist';
  }

  @override
  String get moveToCart => 'Move to cart';

  @override
  String get checkoutSummary => 'Order summary';

  @override
  String couponLabel(String code) {
    return 'Coupon ($code)';
  }

  @override
  String get couponApply => 'Apply';

  @override
  String get removeCoupon => 'Remove coupon';

  @override
  String get couponCodeHint => 'e.g. SAVE10';

  @override
  String get cartTitle => 'Cart';

  @override
  String get clearCart => 'Clear cart';

  @override
  String get clearCartTitle => 'Clear cart?';

  @override
  String get clearCartMessage => 'Every item will be removed from your cart.';

  @override
  String get clear => 'Clear';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyMessage => 'Add something you like from the catalog.';

  @override
  String get browseProducts => 'Browse products';

  @override
  String onlyXLeftInStock(int stock) {
    return 'Only $stock left in stock';
  }

  @override
  String get removeOne => 'Remove one';

  @override
  String get addOne => 'Add one';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get savings => 'Savings';

  @override
  String get total => 'Total';

  @override
  String get checkout => 'Checkout';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get shippingDetails => 'Shipping details';

  @override
  String get codOnlyNote =>
      'Cash on delivery only — pay when your order arrives.';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get saveDetailsNextTime => 'Save my details for next time';

  @override
  String get placeOrderCod => 'Place order — Cash on delivery';

  @override
  String get orderPlaced => 'Order placed!';

  @override
  String orderPlacedSummary(String number, String total) {
    return 'Order $number · $total';
  }

  @override
  String weWillCall(String phone) {
    return 'We will call $phone to confirm delivery details.';
  }

  @override
  String get backToShop => 'Back to shop';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get phoneRequired => 'Phone is required';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get profileTitle => 'Profile';

  @override
  String get yourDetails => 'Your details';

  @override
  String get profileHint =>
      'Used to pre-fill the checkout form. Orders always carry their own snapshot of these details.';

  @override
  String get noSavedDetails =>
      'No saved details yet — fill them in here, or checkout will save them automatically.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String get adminDashboardSubtitle => 'PIN-protected shop management';

  @override
  String get adminTitle => 'Admin';

  @override
  String get couldNotCheckPin =>
      'Could not check PIN status. Please restart the app.';

  @override
  String get setAdminPin => 'Set an admin PIN';

  @override
  String get enterAdminPin => 'Enter admin PIN';

  @override
  String get setPinHint => 'Create a 4-6 digit PIN to lock the dashboard.';

  @override
  String get enterPinHint => 'Unlock the dashboard with your PIN.';

  @override
  String get pinLabel => 'PIN';

  @override
  String get setPin => 'Set PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get pinFormatError => 'PIN must be 4-6 digits';

  @override
  String get pinNotSet => 'PIN has not been set';

  @override
  String get pinIncorrect => 'Incorrect PIN';

  @override
  String get overviewTitle => 'Overview';

  @override
  String get revenue => 'Revenue';

  @override
  String get orders => 'Orders';

  @override
  String get lowStock => 'Low stock';

  @override
  String get ordersByStatus => 'Orders by status';

  @override
  String get recentOrders => 'Recent orders';

  @override
  String get overviewActiveCoupons => 'Active coupons';

  @override
  String get couponUsageTitle => 'Coupon usage';

  @override
  String get noCouponUsage => 'No coupon usage yet.';

  @override
  String get topCouponsTitle => 'Top coupons';

  @override
  String get noTopCoupons => 'No coupons used yet.';

  @override
  String couponUsesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uses',
      one: '1 use',
    );
    return '$_temp0';
  }

  @override
  String couponUsedPercent(int percent) {
    return '$percent% used';
  }

  @override
  String get noOrdersYet => 'No orders yet.';

  @override
  String get allStockedUp => 'All stocked up.';

  @override
  String onlyXLeft(int stock) {
    return 'Only $stock left';
  }

  @override
  String get myOrders => 'My Orders';

  @override
  String get noOrdersTitle => 'No orders yet';

  @override
  String get noOrdersMessage =>
      'Your order history will appear here after your first checkout.';

  @override
  String get orderTitle => 'Order';

  @override
  String get couldNotLoadOrder => 'Could not load order';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get orderRemoved => 'This order may have been removed.';

  @override
  String itemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String placedAt(String date) {
    return 'Placed $date';
  }

  @override
  String get deliverTo => 'Deliver to';

  @override
  String get items => 'Items';

  @override
  String get status => 'Status';

  @override
  String get noStatusHistory => 'No status history yet.';

  @override
  String percentOff(int percent) {
    return '($percent% off)';
  }

  @override
  String get couponsTitle => 'Coupons';

  @override
  String get newCoupon => 'New coupon';

  @override
  String get editCoupon => 'Edit coupon';

  @override
  String get couponNotFoundView => 'Coupon not found';

  @override
  String get deleteCouponTitle => 'Delete coupon?';

  @override
  String deleteCouponMessage(String code) {
    return '$code will be removed. Past orders keep their snapshot.';
  }

  @override
  String deleteCouponTooltip(String code) {
    return 'Delete $code';
  }

  @override
  String get noCouponsTitle => 'No coupons yet';

  @override
  String get noCouponsMessage => 'Create a code to start promoting.';

  @override
  String get couponCode => 'Code';

  @override
  String get couponFixedType => 'Fixed amount';

  @override
  String get couponFixedValue => 'Discount amount';

  @override
  String couponPercentOff(int value) {
    return '$value% off';
  }

  @override
  String couponFixedOff(String amount) {
    return '$amount off';
  }

  @override
  String get minSpendOptional => 'Minimum spend (optional)';

  @override
  String get minSpendHint => '0 = no minimum';

  @override
  String couponMinSpendShort(String amount) {
    return 'min $amount';
  }

  @override
  String get expiryOptional => 'Expiry date (optional)';

  @override
  String get neverExpires => 'Never';

  @override
  String get removeExpiry => 'Remove expiry';

  @override
  String get maxUsesOptional => 'Usage limit (optional)';

  @override
  String get unlimited => 'Unlimited';

  @override
  String couponUsesLeft(int used, int max) {
    return '$used/$max uses';
  }

  @override
  String get couponActive => 'Active';

  @override
  String get activeStatus => 'Active';

  @override
  String get inactiveStatus => 'Inactive';

  @override
  String get expiredStatus => 'Expired';

  @override
  String noFilterOrdersTitle(String status) {
    return 'No $status orders';
  }

  @override
  String get ordersWillAppear =>
      'Orders will appear here once customers check out.';

  @override
  String get tryDifferentFilter => 'Try a different status filter.';

  @override
  String get showAllOrders => 'Show all orders';

  @override
  String markedAs(String order, String status) {
    return '$order marked as $status';
  }

  @override
  String orderTerminalNote(String status) {
    return 'This order is $status — no further actions.';
  }

  @override
  String get noFurtherActions => 'No further actions available.';

  @override
  String get actions => 'Actions';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String markAs(String status) {
    return 'Mark $status';
  }

  @override
  String get productsTitle => 'Products';

  @override
  String get newProduct => 'New product';

  @override
  String get deleteProductTitle => 'Delete product?';

  @override
  String deleteProductMessage(String name) {
    return '$name will be removed permanently. Orders that reference it keep their snapshot.';
  }

  @override
  String get noProductsTitle => 'No products yet';

  @override
  String get noProductsMessage => 'Create the first product to start selling.';

  @override
  String get lowStockShort => 'Low stock';

  @override
  String stockInStock(int stock) {
    return '$stock in stock';
  }

  @override
  String deleteProductTooltip(String name) {
    return 'Delete $name';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get newCategory => 'New category';

  @override
  String get renameCategory => 'Rename category';

  @override
  String deleteCategoryTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteCategoryMessage =>
      'Categories that still have products cannot be deleted.';

  @override
  String get categoryName => 'Category name';

  @override
  String get noCategoriesTitle => 'No categories yet';

  @override
  String get noCategoriesMessage => 'Create a category before adding products.';

  @override
  String renameTooltip(String name) {
    return 'Rename $name';
  }

  @override
  String deleteCategoryTooltip(String name) {
    return 'Delete $name';
  }

  @override
  String get editProduct => 'Edit product';

  @override
  String get addImage => 'Add image';

  @override
  String get replaceImage => 'Replace image';

  @override
  String get removeImage => 'Remove image';

  @override
  String get name => 'Name';

  @override
  String get category => 'Category';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get price => 'Price';

  @override
  String get discountPercent => 'Discount %';

  @override
  String get stock => 'Stock';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get arabicNameOptional => 'Arabic name (optional)';

  @override
  String get arabicDescriptionOptional => 'Arabic description (optional)';

  @override
  String get saveProduct => 'Save product';

  @override
  String get requiredField => 'Required';

  @override
  String get priceGreaterThanZero => 'Enter a price greater than 0';

  @override
  String get percentRange => '0-100';

  @override
  String get stockNonNegative => '0 or more';

  @override
  String get errorLoadFailed =>
      'Couldn\'t load this right now. Please try again.';

  @override
  String get errorDatabase => 'Something went wrong. Please try again.';

  @override
  String get errorProductNotFound => 'Product not found.';

  @override
  String get errorCategoryNotFound => 'Category not found.';

  @override
  String get errorOrderNotFound => 'Order not found.';

  @override
  String get errorCartProductUnavailable =>
      'A product in your cart is no longer available.';

  @override
  String get errorQuantityMin => 'Quantity must be at least 1.';

  @override
  String errorProductOutOfStock(String product) {
    return '$product is out of stock.';
  }

  @override
  String errorStockLimit(int stock, String product) {
    return 'Only $stock left in stock for $product.';
  }

  @override
  String errorStockLimitHint(int count) {
    return 'You already have $count in your cart.';
  }

  @override
  String get errorCartEmpty => 'Your cart is empty.';

  @override
  String get errorInvalidStatusTransition =>
      'This status change is not allowed.';

  @override
  String errorCategoryInUse(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This category has $count products. Delete them before deleting the category.',
      one:
          'This category has 1 product. Delete it before deleting the category.',
    );
    return '$_temp0';
  }

  @override
  String get errorImageSave => 'Could not save the image.';

  @override
  String get errorImageDelete => 'Could not delete the image.';

  @override
  String errorCouponNotFound(String code) {
    return '$code is not a valid code.';
  }

  @override
  String errorCouponInactive(String code) {
    return 'Code $code is not active.';
  }

  @override
  String errorCouponExpired(String code) {
    return 'Code $code has expired.';
  }

  @override
  String errorCouponMinSpend(String current, String required) {
    return 'Spend at least $required to use this code (your subtotal is $current).';
  }

  @override
  String errorCouponUsageLimit(String code, int maxUses) {
    return 'Code $code has reached its $maxUses-use limit.';
  }

  @override
  String get errorCouponCodeTaken => 'That code is already in use.';
}

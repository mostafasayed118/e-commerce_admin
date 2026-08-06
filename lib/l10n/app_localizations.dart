import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get tabCart;

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tabOrders;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get tabProducts;

  /// No description provided for @tabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tabCategories;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get statusShipped;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get sortName;

  /// No description provided for @sortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceDesc;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @catalogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The catalog is empty'**
  String get catalogEmptyTitle;

  /// No description provided for @catalogEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Products will appear here once they exist.'**
  String get catalogEmptyMessage;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// Product count line on the catalog header and the admin categories rows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 product} other{{count} products}}'**
  String productCount(num count);

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @noMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your current search or filter.'**
  String get noMatchesMessage;

  /// No description provided for @noProductsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No products in this category yet.'**
  String get noProductsInCategory;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @lowStockLeft.
  ///
  /// In en, this message translates to:
  /// **'Low stock: {stock} left'**
  String lowStockLeft(int stock);

  /// No description provided for @productTitle.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productTitle;

  /// No description provided for @couldNotLoadProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not load product'**
  String get couldNotLoadProduct;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @productRemovedFromCatalog.
  ///
  /// In en, this message translates to:
  /// **'This product may have been deleted.'**
  String get productRemovedFromCatalog;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get adding;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'{product} added to cart'**
  String addedToCart(String product);

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get clearCart;

  /// No description provided for @clearCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cart?'**
  String get clearCartTitle;

  /// No description provided for @clearCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Every item will be removed from your cart.'**
  String get clearCartMessage;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add something you like from the catalog.'**
  String get cartEmptyMessage;

  /// No description provided for @browseProducts.
  ///
  /// In en, this message translates to:
  /// **'Browse products'**
  String get browseProducts;

  /// No description provided for @onlyXLeftInStock.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} left in stock'**
  String onlyXLeftInStock(int stock);

  /// No description provided for @removeOne.
  ///
  /// In en, this message translates to:
  /// **'Remove one'**
  String get removeOne;

  /// No description provided for @addOne.
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get addOne;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @shippingDetails.
  ///
  /// In en, this message translates to:
  /// **'Shipping details'**
  String get shippingDetails;

  /// No description provided for @codOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery only — pay when your order arrives.'**
  String get codOnlyNote;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @saveDetailsNextTime.
  ///
  /// In en, this message translates to:
  /// **'Save my details for next time'**
  String get saveDetailsNextTime;

  /// No description provided for @placeOrderCod.
  ///
  /// In en, this message translates to:
  /// **'Place order — Cash on delivery'**
  String get placeOrderCod;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderPlaced;

  /// No description provided for @orderPlacedSummary.
  ///
  /// In en, this message translates to:
  /// **'Order {number} · {total}'**
  String orderPlacedSummary(String number, String total);

  /// No description provided for @weWillCall.
  ///
  /// In en, this message translates to:
  /// **'We will call {phone} to confirm delivery details.'**
  String weWillCall(String phone);

  /// No description provided for @backToShop.
  ///
  /// In en, this message translates to:
  /// **'Back to shop'**
  String get backToShop;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @yourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get yourDetails;

  /// No description provided for @profileHint.
  ///
  /// In en, this message translates to:
  /// **'Used to pre-fill the checkout form. Orders always carry their own snapshot of these details.'**
  String get profileHint;

  /// No description provided for @noSavedDetails.
  ///
  /// In en, this message translates to:
  /// **'No saved details yet — fill them in here, or checkout will save them automatically.'**
  String get noSavedDetails;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboard;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PIN-protected shop management'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @couldNotCheckPin.
  ///
  /// In en, this message translates to:
  /// **'Could not check PIN status. Please restart the app.'**
  String get couldNotCheckPin;

  /// No description provided for @setAdminPin.
  ///
  /// In en, this message translates to:
  /// **'Set an admin PIN'**
  String get setAdminPin;

  /// No description provided for @enterAdminPin.
  ///
  /// In en, this message translates to:
  /// **'Enter admin PIN'**
  String get enterAdminPin;

  /// No description provided for @setPinHint.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-6 digit PIN to lock the dashboard.'**
  String get setPinHint;

  /// No description provided for @enterPinHint.
  ///
  /// In en, this message translates to:
  /// **'Unlock the dashboard with your PIN.'**
  String get enterPinHint;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @pinFormatError.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4-6 digits'**
  String get pinFormatError;

  /// No description provided for @pinNotSet.
  ///
  /// In en, this message translates to:
  /// **'PIN has not been set'**
  String get pinNotSet;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get pinIncorrect;

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @ordersByStatus.
  ///
  /// In en, this message translates to:
  /// **'Orders by status'**
  String get ordersByStatus;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent orders'**
  String get recentOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get noOrdersYet;

  /// No description provided for @allStockedUp.
  ///
  /// In en, this message translates to:
  /// **'All stocked up.'**
  String get allStockedUp;

  /// No description provided for @onlyXLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} left'**
  String onlyXLeft(int stock);

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @noOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersTitle;

  /// No description provided for @noOrdersMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here after your first checkout.'**
  String get noOrdersMessage;

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderTitle;

  /// No description provided for @couldNotLoadOrder.
  ///
  /// In en, this message translates to:
  /// **'Could not load order'**
  String get couldNotLoadOrder;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @orderRemoved.
  ///
  /// In en, this message translates to:
  /// **'This order may have been removed.'**
  String get orderRemoved;

  /// Line item count on order tiles and category rows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item} other{{count} items}}'**
  String itemCount(num count);

  /// No description provided for @placedAt.
  ///
  /// In en, this message translates to:
  /// **'Placed {date}'**
  String placedAt(String date);

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @noStatusHistory.
  ///
  /// In en, this message translates to:
  /// **'No status history yet.'**
  String get noStatusHistory;

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'({percent}% off)'**
  String percentOff(int percent);

  /// No description provided for @noFilterOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'No {status} orders'**
  String noFilterOrdersTitle(String status);

  /// No description provided for @ordersWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Orders will appear here once customers check out.'**
  String get ordersWillAppear;

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different status filter.'**
  String get tryDifferentFilter;

  /// No description provided for @showAllOrders.
  ///
  /// In en, this message translates to:
  /// **'Show all orders'**
  String get showAllOrders;

  /// No description provided for @markedAs.
  ///
  /// In en, this message translates to:
  /// **'{order} marked as {status}'**
  String markedAs(String order, String status);

  /// No description provided for @orderTerminalNote.
  ///
  /// In en, this message translates to:
  /// **'This order is {status} — no further actions.'**
  String orderTerminalNote(String status);

  /// No description provided for @noFurtherActions.
  ///
  /// In en, this message translates to:
  /// **'No further actions available.'**
  String get noFurtherActions;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @markAs.
  ///
  /// In en, this message translates to:
  /// **'Mark {status}'**
  String markAs(String status);

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get newProduct;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed permanently. Orders that reference it keep their snapshot.'**
  String deleteProductMessage(String name);

  /// No description provided for @noProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsTitle;

  /// No description provided for @noProductsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create the first product to start selling.'**
  String get noProductsMessage;

  /// No description provided for @lowStockShort.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockShort;

  /// No description provided for @stockInStock.
  ///
  /// In en, this message translates to:
  /// **'{stock} in stock'**
  String stockInStock(int stock);

  /// No description provided for @deleteProductTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteProductTooltip(String name);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get renameCategory;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteCategoryTitle(String name);

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Categories that still have products cannot be deleted.'**
  String get deleteCategoryMessage;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @noCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesTitle;

  /// No description provided for @noCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a category before adding products.'**
  String get noCategoriesMessage;

  /// No description provided for @renameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename {name}'**
  String renameTooltip(String name);

  /// No description provided for @deleteCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteCategoryTooltip(String name);

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @replaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get replaceImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount %'**
  String get discountPercent;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @arabicNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Arabic name (optional)'**
  String get arabicNameOptional;

  /// No description provided for @arabicDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Arabic description (optional)'**
  String get arabicDescriptionOptional;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save product'**
  String get saveProduct;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @priceGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter a price greater than 0'**
  String get priceGreaterThanZero;

  /// No description provided for @percentRange.
  ///
  /// In en, this message translates to:
  /// **'0-100'**
  String get percentRange;

  /// No description provided for @stockNonNegative.
  ///
  /// In en, this message translates to:
  /// **'0 or more'**
  String get stockNonNegative;

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this right now. Please try again.'**
  String get errorLoadFailed;

  /// No description provided for @errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorDatabase;

  /// No description provided for @errorProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found.'**
  String get errorProductNotFound;

  /// No description provided for @errorCategoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found.'**
  String get errorCategoryNotFound;

  /// No description provided for @errorOrderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get errorOrderNotFound;

  /// No description provided for @errorCartProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A product in your cart is no longer available.'**
  String get errorCartProductUnavailable;

  /// No description provided for @errorQuantityMin.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be at least 1.'**
  String get errorQuantityMin;

  /// No description provided for @errorProductOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'{product} is out of stock.'**
  String errorProductOutOfStock(String product);

  /// No description provided for @errorStockLimit.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} left in stock for {product}.'**
  String errorStockLimit(int stock, String product);

  /// No description provided for @errorStockLimitHint.
  ///
  /// In en, this message translates to:
  /// **'You already have {count} in your cart.'**
  String errorStockLimitHint(int count);

  /// No description provided for @errorCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get errorCartEmpty;

  /// No description provided for @errorInvalidStatusTransition.
  ///
  /// In en, this message translates to:
  /// **'This status change is not allowed.'**
  String get errorInvalidStatusTransition;

  /// No description provided for @errorCategoryInUse.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{This category has 1 product. Delete it before deleting the category.} other{This category has {count} products. Delete them before deleting the category.}}'**
  String errorCategoryInUse(num count);

  /// No description provided for @errorImageSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save the image.'**
  String get errorImageSave;

  /// No description provided for @errorImageDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the image.'**
  String get errorImageDelete;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get backToStore => 'العودة إلى المتجر';

  @override
  String get create => 'إنشاء';

  @override
  String get all => 'الكل';

  @override
  String get tabShop => 'المتجر';

  @override
  String get tabWishlist => 'المفضلة';

  @override
  String get tabCart => 'السلة';

  @override
  String get tabOrders => 'الطلبات';

  @override
  String get tabProfile => 'الملف الشخصي';

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabProducts => 'المنتجات';

  @override
  String get tabCategories => 'التصنيفات';

  @override
  String get tabCoupons => 'القسائم';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusConfirmed => 'مؤكد';

  @override
  String get statusShipped => 'تم الشحن';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get sortName => 'الاسم أ-ي';

  @override
  String get sortPriceAsc => 'السعر: من الأقل إلى الأعلى';

  @override
  String get sortPriceDesc => 'السعر: من الأعلى إلى الأقل';

  @override
  String get shopTitle => 'المتجر';

  @override
  String get catalogEmptyTitle => 'المتجر فارغ';

  @override
  String get catalogEmptyMessage => 'ستظهر المنتجات هنا فور توفرها.';

  @override
  String get searchProducts => 'ابحث عن المنتجات';

  @override
  String productCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتجًا',
      many: '$count منتجًا',
      few: '$count منتجات',
      two: 'منتجان',
      one: 'منتج واحد',
      zero: 'لا منتجات',
    );
    return '$_temp0';
  }

  @override
  String get noMatches => 'لا توجد نتائج';

  @override
  String get noMatchesMessage => 'لا يوجد ما يطابق بحثك أو فلترك الحالي.';

  @override
  String get noProductsInCategory => 'لا توجد منتجات في هذا التصنيف بعد.';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get outOfStock => 'نفدت الكمية';

  @override
  String lowStockLeft(int stock) {
    return 'كمية منخفضة: متبقي $stock';
  }

  @override
  String get productTitle => 'المنتج';

  @override
  String get couldNotLoadProduct => 'تعذّر تحميل المنتج';

  @override
  String get productNotFound => 'المنتج غير موجود';

  @override
  String get productRemovedFromCatalog => 'ربما تم حذف هذا المنتج.';

  @override
  String get inStock => 'متوفر';

  @override
  String get noDescription => 'لا يتوفر وصف.';

  @override
  String get adding => 'جارٍ الإضافة…';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String addedToCart(String product) {
    return 'تمت إضافة $product إلى السلة';
  }

  @override
  String get wishlistTitle => 'المفضلة';

  @override
  String get wishlistEmptyTitle => 'قائمة المفضلة فارغة';

  @override
  String get wishlistEmptyMessage =>
      'اضغط على القلب في أي منتج لحفظه لوقت لاحق.';

  @override
  String get addToWishlist => 'أضف إلى المفضلة';

  @override
  String get removeFromWishlist => 'أزل من المفضلة';

  @override
  String addedToWishlist(String product) {
    return 'تمت إضافة $product إلى المفضلة';
  }

  @override
  String removedFromWishlist(String product) {
    return 'تمت إزالة $product من المفضلة';
  }

  @override
  String get moveToCart => 'نقل إلى السلة';

  @override
  String get checkoutSummary => 'ملخص الطلب';

  @override
  String couponLabel(String code) {
    return 'القسيمة ($code)';
  }

  @override
  String get couponApply => 'تطبيق';

  @override
  String get removeCoupon => 'إزالة القسيمة';

  @override
  String get couponCodeHint => 'مثال: SAVE10';

  @override
  String get cartTitle => 'السلة';

  @override
  String get clearCart => 'إفراغ السلة';

  @override
  String get clearCartTitle => 'إفراغ السلة؟';

  @override
  String get clearCartMessage => 'ستتم إزالة جميع العناصر من سلتك.';

  @override
  String get clear => 'إفراغ';

  @override
  String get cartEmptyTitle => 'سلتك فارغة';

  @override
  String get cartEmptyMessage => 'أضف ما يعجبك من المتجر.';

  @override
  String get browseProducts => 'تصفح المنتجات';

  @override
  String onlyXLeftInStock(int stock) {
    return 'متبقي $stock فقط في المخزون';
  }

  @override
  String get removeOne => 'إزالة واحد';

  @override
  String get addOne => 'إضافة واحد';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get savings => 'التوفير';

  @override
  String get total => 'الإجمالي';

  @override
  String get checkout => 'إتمام الطلب';

  @override
  String get checkoutTitle => 'إتمام الطلب';

  @override
  String get shippingDetails => 'بيانات الشحن';

  @override
  String get codOnlyNote => 'الدفع عند الاستلام فقط — ادفع عند وصول طلبك.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phone => 'الهاتف';

  @override
  String get deliveryAddress => 'عنوان التوصيل';

  @override
  String get saveDetailsNextTime => 'احفظ بياناتي للمرة القادمة';

  @override
  String get placeOrderCod => 'تأكيد الطلب — الدفع عند الاستلام';

  @override
  String get orderPlaced => 'تم تقديم الطلب!';

  @override
  String orderPlacedSummary(String number, String total) {
    return 'الطلب $number · $total';
  }

  @override
  String weWillCall(String phone) {
    return 'سنتصل بك على $phone لتأكيد تفاصيل التوصيل.';
  }

  @override
  String get backToShop => 'العودة إلى المتجر';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get addressRequired => 'العنوان مطلوب';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get yourDetails => 'بياناتك';

  @override
  String get profileHint =>
      'تُستخدم لتعبئة نموذج إتمام الطلب مسبقًا. تحمل الطلبات دائمًا نسخة خاصة بها من هذه البيانات.';

  @override
  String get noSavedDetails =>
      'لا توجد بيانات محفوظة بعد — أدخلها هنا، أو سيقوم إتمام الطلب بحفظها تلقائيًا.';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي.';

  @override
  String get saveProfile => 'حفظ الملف الشخصي';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get system => 'النظام';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get adminDashboard => 'لوحة الإدارة';

  @override
  String get adminDashboardSubtitle => 'إدارة المتجر المحمية برمز PIN';

  @override
  String get adminTitle => 'الإدارة';

  @override
  String get couldNotCheckPin =>
      'تعذّر التحقق من حالة رمز PIN. يرجى إعادة تشغيل التطبيق.';

  @override
  String get setAdminPin => 'تعيين رمز PIN للإدارة';

  @override
  String get enterAdminPin => 'أدخل رمز PIN';

  @override
  String get setPinHint => 'أنشئ رمز PIN من 4-6 أرقام لقفل لوحة التحكم.';

  @override
  String get enterPinHint => 'افتح لوحة التحكم برمز PIN الخاص بك.';

  @override
  String get pinLabel => 'رمز PIN';

  @override
  String get setPin => 'تعيين الرمز';

  @override
  String get unlock => 'فتح';

  @override
  String get pinFormatError => 'يجب أن يتكون رمز PIN من 4-6 أرقام';

  @override
  String get pinNotSet => 'لم يتم تعيين رمز PIN';

  @override
  String get pinIncorrect => 'رمز PIN غير صحيح';

  @override
  String get overviewTitle => 'نظرة عامة';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get orders => 'الطلبات';

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get ordersByStatus => 'الطلبات حسب الحالة';

  @override
  String get recentOrders => 'أحدث الطلبات';

  @override
  String get overviewActiveCoupons => 'قسائم نشطة';

  @override
  String get couponUsageTitle => 'استخدام القسائم';

  @override
  String get noCouponUsage => 'لا يوجد استخدام للقسائم بعد.';

  @override
  String get topCouponsTitle => 'أفضل القسائم';

  @override
  String get noTopCoupons => 'لا توجد قسائم مستخدمة بعد.';

  @override
  String couponUsesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count استخدامًا',
      many: '$count استخدامًا',
      few: '$count استخدامات',
      two: 'استخدامان',
      one: 'استخدام واحد',
      zero: 'لا استخدامات',
    );
    return '$_temp0';
  }

  @override
  String couponUsedPercent(int percent) {
    return '$percent% مستخدمة';
  }

  @override
  String get noOrdersYet => 'لا توجد طلبات بعد.';

  @override
  String get allStockedUp => 'المخزون مكتمل.';

  @override
  String onlyXLeft(int stock) {
    return 'متبقي $stock فقط';
  }

  @override
  String get myOrders => 'طلباتي';

  @override
  String get noOrdersTitle => 'لا توجد طلبات بعد';

  @override
  String get noOrdersMessage => 'سيظهر سجل طلباتك هنا بعد أول عملية شراء.';

  @override
  String get orderTitle => 'الطلب';

  @override
  String get couldNotLoadOrder => 'تعذّر تحميل الطلب';

  @override
  String get orderNotFound => 'الطلب غير موجود';

  @override
  String get orderRemoved => 'ربما تمت إزالة هذا الطلب.';

  @override
  String itemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصرًا',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String placedAt(String date) {
    return 'تم الطلب في $date';
  }

  @override
  String get deliverTo => 'التوصيل إلى';

  @override
  String get items => 'العناصر';

  @override
  String get status => 'الحالة';

  @override
  String get noStatusHistory => 'لا يوجد سجل للحالة بعد.';

  @override
  String percentOff(int percent) {
    return '(خصم $percent%)';
  }

  @override
  String get couponsTitle => 'القسائم';

  @override
  String get newCoupon => 'قسيمة جديدة';

  @override
  String get editCoupon => 'تعديل القسيمة';

  @override
  String get couponNotFoundView => 'القسيمة غير موجودة';

  @override
  String get deleteCouponTitle => 'حذف القسيمة؟';

  @override
  String deleteCouponMessage(String code) {
    return 'ستتم إزالة $code. تحتفظ الطلبات السابقة بنسختها المحفوظة.';
  }

  @override
  String deleteCouponTooltip(String code) {
    return 'حذف $code';
  }

  @override
  String get noCouponsTitle => 'لا توجد قسائم بعد';

  @override
  String get noCouponsMessage => 'أنشئ رمزًا لبدء الترويج.';

  @override
  String get couponCode => 'الرمز';

  @override
  String get couponFixedType => 'مبلغ ثابت';

  @override
  String get couponFixedValue => 'مبلغ الخصم';

  @override
  String couponPercentOff(int value) {
    return 'خصم $value%';
  }

  @override
  String couponFixedOff(String amount) {
    return 'خصم $amount';
  }

  @override
  String get minSpendOptional => 'الحد الأدنى للشراء (اختياري)';

  @override
  String get minSpendHint => '0 = بدون حد أدنى';

  @override
  String couponMinSpendShort(String amount) {
    return 'الحد الأدنى $amount';
  }

  @override
  String get expiryOptional => 'تاريخ الانتهاء (اختياري)';

  @override
  String get neverExpires => 'لا ينتهي';

  @override
  String get removeExpiry => 'إزالة تاريخ الانتهاء';

  @override
  String get maxUsesOptional => 'حد الاستخدام (اختياري)';

  @override
  String get unlimited => 'غير محدود';

  @override
  String couponUsesLeft(int used, int max) {
    return '$used/$max استخدامات';
  }

  @override
  String get couponActive => 'نشطة';

  @override
  String get activeStatus => 'نشطة';

  @override
  String get inactiveStatus => 'معطّلة';

  @override
  String get expiredStatus => 'منتهية';

  @override
  String get ordersWillAppear =>
      'ستظهر الطلبات هنا بعد أن يقوم العملاء بإتمام الشراء.';

  @override
  String markedAs(String order, String status) {
    return 'تم تحديث $order إلى الحالة: $status';
  }

  @override
  String orderTerminalNote(String status) {
    return 'هذا الطلب $status — لا مزيد من الإجراءات.';
  }

  @override
  String get noFurtherActions => 'لا توجد إجراءات إضافية متاحة.';

  @override
  String get actions => 'الإجراءات';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String markAs(String status) {
    return 'تحديد $status';
  }

  @override
  String get productsTitle => 'المنتجات';

  @override
  String get newProduct => 'منتج جديد';

  @override
  String get deleteProductTitle => 'حذف المنتج؟';

  @override
  String deleteProductMessage(String name) {
    return 'سيتم حذف $name نهائيًا. تحتفظ الطلبات التي تشير إليه بنسختها المحفوظة.';
  }

  @override
  String get noProductsTitle => 'لا توجد منتجات بعد';

  @override
  String get noProductsMessage => 'أنشئ أول منتج لبدء البيع.';

  @override
  String get lowStockShort => 'مخزون منخفض';

  @override
  String stockInStock(int stock) {
    return '$stock في المخزون';
  }

  @override
  String deleteProductTooltip(String name) {
    return 'حذف $name';
  }

  @override
  String get categoriesTitle => 'التصنيفات';

  @override
  String get newCategory => 'تصنيف جديد';

  @override
  String get renameCategory => 'إعادة تسمية التصنيف';

  @override
  String deleteCategoryTitle(String name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get deleteCategoryMessage =>
      'لا يمكن حذف التصنيفات التي لا تزال تحتوي على منتجات.';

  @override
  String get categoryName => 'اسم التصنيف';

  @override
  String get noCategoriesTitle => 'لا توجد تصنيفات بعد';

  @override
  String get noCategoriesMessage => 'أنشئ تصنيفًا قبل إضافة المنتجات.';

  @override
  String renameTooltip(String name) {
    return 'إعادة تسمية $name';
  }

  @override
  String deleteCategoryTooltip(String name) {
    return 'حذف $name';
  }

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get addImage => 'إضافة صورة';

  @override
  String get replaceImage => 'استبدال الصورة';

  @override
  String get removeImage => 'إزالة الصورة';

  @override
  String get name => 'الاسم';

  @override
  String get category => 'التصنيف';

  @override
  String get chooseCategory => 'اختر تصنيفًا';

  @override
  String get price => 'السعر';

  @override
  String get discountPercent => 'الخصم %';

  @override
  String get stock => 'المخزون';

  @override
  String get descriptionOptional => 'الوصف (اختياري)';

  @override
  String get arabicNameOptional => 'الاسم بالعربية (اختياري)';

  @override
  String get arabicDescriptionOptional => 'الوصف بالعربية (اختياري)';

  @override
  String get saveProduct => 'حفظ المنتج';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get priceGreaterThanZero => 'أدخل سعرًا أكبر من 0';

  @override
  String get percentRange => '0-100';

  @override
  String get stockNonNegative => '0 أو أكثر';

  @override
  String get errorLoadFailed => 'تعذّر التحميل الآن. حاول مرة أخرى.';

  @override
  String get errorDatabase => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorProductNotFound => 'المنتج غير موجود.';

  @override
  String get errorCategoryNotFound => 'التصنيف غير موجود.';

  @override
  String get errorOrderNotFound => 'الطلب غير موجود.';

  @override
  String get errorCartProductUnavailable =>
      'أحد المنتجات في سلتك لم يعد متوفرًا.';

  @override
  String get errorQuantityMin => 'يجب أن تكون الكمية 1 على الأقل.';

  @override
  String errorProductOutOfStock(String product) {
    return 'نفدت كمية $product.';
  }

  @override
  String errorStockLimit(int stock, String product) {
    return 'متبقي $stock فقط في المخزون من $product.';
  }

  @override
  String errorStockLimitHint(int count) {
    return 'لديك بالفعل $count في سلتك.';
  }

  @override
  String get errorCartEmpty => 'سلتك فارغة.';

  @override
  String get errorInvalidStatusTransition => 'تغيير الحالة هذا غير مسموح به.';

  @override
  String errorCategoryInUse(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يحتوي هذا التصنيف على $count منتجًا. احذفها قبل حذف التصنيف.',
      many: 'يحتوي هذا التصنيف على $count منتجًا. احذفها قبل حذف التصنيف.',
      few: 'يحتوي هذا التصنيف على $count منتجات. احذفها قبل حذف التصنيف.',
      two: 'يحتوي هذا التصنيف على منتجين. احذفهما قبل حذف التصنيف.',
      one: 'يحتوي هذا التصنيف على منتج واحد. احذفه قبل حذف التصنيف.',
      zero: 'لا يحتوي هذا التصنيف على منتجات.',
    );
    return '$_temp0';
  }

  @override
  String get errorImageSave => 'تعذّر حفظ الصورة.';

  @override
  String get errorImageDelete => 'تعذّر حذف الصورة.';

  @override
  String errorCouponNotFound(String code) {
    return '$code ليس رمزًا صالحًا.';
  }

  @override
  String errorCouponInactive(String code) {
    return 'الرمز $code غير نشط.';
  }

  @override
  String errorCouponExpired(String code) {
    return 'انتهت صلاحية الرمز $code.';
  }

  @override
  String errorCouponMinSpend(String current, String required) {
    return 'أنفق $required على الأقل لاستخدام هذا الرمز (مجموعك الحالي $current).';
  }

  @override
  String errorCouponUsageLimit(String code, int maxUses) {
    return 'بلغ الرمز $code الحد الأقصى لاستخداماته ($maxUses).';
  }

  @override
  String get errorCouponCodeTaken => 'هذا الرمز مستخدم بالفعل.';

  @override
  String get searchOrders => 'ابحث في الطلبات';

  @override
  String get fromDate => 'من';

  @override
  String get toDate => 'إلى';

  @override
  String get clearDates => 'مسح التواريخ';

  @override
  String get noOrdersMatchTitle => 'لا توجد طلبات مطابقة';

  @override
  String get noOrdersMatchMessage => 'جرّب فلاتر مختلفة.';

  @override
  String get exportOrders => 'تصدير الطلبات';

  @override
  String exportDone(int count) {
    return 'تم تصدير $count طلبًا إلى CSV.';
  }
}

import 'package:flutter/widgets.dart';

import '../../core/entities/category.dart';
import '../../core/entities/order_item.dart';
import '../../core/entities/product.dart';
import '../../core/error/app_error.dart';
import '../../core/utils/money.dart' as money;
import '../../l10n/app_localizations.dart';
import 'error_messages.dart';

/// Shortcut for the generated [AppLocalizations] on a [BuildContext].
///
/// `AppLocalizations.of(context)` is non-null by construction (nullable-getter:
/// false in l10n.yaml), so screens write `context.l10n.cartTitle` instead of
/// `AppLocalizations.of(context)!.cartTitle` — the same brevity contract the
/// rest of the presentation layer uses (e.g. `context.read<Cubit>()`).
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Formats [cents] with the active locale's number/currency conventions.
  ///
  /// Resolves the locale once, here, so call sites stay `context.formatCents(x)`
  /// instead of threading `Localizations.localeOf(context)` everywhere.
  /// (`languageCode` is exact: the app only ever runs `en` or `ar`.)
  String formatCents(int cents) => money.formatCents(
        cents,
        locale: Localizations.localeOf(this).languageCode,
      );

  /// The active locale's message for [error], mapped from its stable code
  /// (typed variants supply the data for parameterized messages).
  String errorText(AppError error) => localizedErrorMessage(this, error);

  /// Translates Western digits in [text] to the active locale's digit shapes
  /// (Eastern Arabic numerals for `ar`, unchanged otherwise) — the same
  /// treatment prices and dates get, so coupon counts and percentages match.
  /// Idempotent for strings that already went through [formatCents].
  String localizeDigits(String text) => money.arabicIndicDigits(
        text,
        Localizations.localeOf(this).languageCode,
      );

  // --- Localized *content* (seed/admin data carries both labels) -----------
  //
  // Unlike UI chrome, product/category names and descriptions are data. The
  // data layer stores the canonical English text plus an optional Arabic
  // variant; these helpers pick by the *viewer's* locale with an English
  // fallback, so a product without Arabic renders its English name in Arabic
  // mode rather than an empty string.

  /// True when the app is running in Arabic.
  bool get _isArabic => Localizations.localeOf(this).languageCode == 'ar';

  /// The product's name in the viewer's locale.
  String productName(Product product) =>
      _isArabic ? _arabicOrNull(product.nameAr) ?? product.name : product.name;

  /// The product's description in the viewer's locale.
  String productDescription(Product product) => _isArabic
      ? _arabicOrNull(product.descriptionAr) ?? product.description
      : product.description;

  /// The category's label in the viewer's locale.
  String categoryName(Category category) =>
      _isArabic ? _arabicOrNull(category.nameAr) ?? category.name : category.name;

  /// An order line's product label in the viewer's locale. The receipt
  /// carries both snapshots (English + Arabic), so the same order renders in
  /// whichever language the viewer is using.
  String orderItemName(OrderItem item) =>
      _isArabic ? _arabicOrNull(item.productNameAr) ?? item.productName : item.productName;

  /// Null-safe, empty-safe Arabic fallback: `''` or whitespace is treated as
  /// "no Arabic text" so a cleared field degrades to English, never blank.
  static String? _arabicOrNull(String? value) => value == null ? null : emptyToNull(value);
}

/// Blank (or whitespace-only) optional content is normalized to `null` at
/// write time (admin forms) and read time ([L10nContext] helpers): the
/// display falls back to English rather than rendering an empty string.
String? emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

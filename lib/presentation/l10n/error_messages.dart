import 'package:flutter/widgets.dart';

import '../../core/error/app_error.dart';
import 'l10n_ext.dart';

/// Maps a stable [AppErrorCode] to a localized message (Task 23 refactor).
///
/// Codes travel from the data/domain layers through [AppError]; the English
/// `message` on the error stays for logs and developer tooling — the UI's
/// source of truth is [AppErrorCode] + this switch, so a third locale is just
/// a new ARB file.
String errorTextForCode(BuildContext context, AppErrorCode code) =>
    switch (code) {
      AppErrorCode.database => context.l10n.errorDatabase,
      AppErrorCode.imageSave => context.l10n.errorImageSave,
      AppErrorCode.imageDelete => context.l10n.errorImageDelete,
      AppErrorCode.productNotFound => context.l10n.errorProductNotFound,
      AppErrorCode.categoryNotFound => context.l10n.errorCategoryNotFound,
      AppErrorCode.orderNotFound => context.l10n.errorOrderNotFound,
      AppErrorCode.cartProductUnavailable =>
        context.l10n.errorCartProductUnavailable,
      AppErrorCode.reviewNotFound => context.l10n.errorReviewNotFound,
      // The minimum (1) is guidance prose — convert like every other number.
      AppErrorCode.quantityMin =>
        context.localizeDigits(context.l10n.errorQuantityMin),
      AppErrorCode.cartEmpty => context.l10n.errorCartEmpty,
      AppErrorCode.invalidStatusTransition =>
        context.l10n.errorInvalidStatusTransition,
      AppErrorCode.nameRequired => context.l10n.nameRequired,
      AppErrorCode.phoneRequired => context.l10n.phoneRequired,
      AppErrorCode.addressRequired => context.l10n.addressRequired,
      // The 4-6 range is guidance prose — convert like every other number.
      AppErrorCode.pinFormat =>
        context.localizeDigits(context.l10n.pinFormatError),
      AppErrorCode.pinNotSet => context.l10n.pinNotSet,
      AppErrorCode.pinIncorrect => context.l10n.pinIncorrect,
      AppErrorCode.couponCodeTaken => context.l10n.errorCouponCodeTaken,
      // The 1-5 range is guidance prose — convert like every other number.
      AppErrorCode.reviewRatingInvalid =>
        context.localizeDigits(context.l10n.errorReviewRatingInvalid),
      // Data-carrying codes are only reachable through their typed variants
      // (handled in [localizedErrorMessage]); a bare code has no data to
      // format, so fall back to the generic message rather than crash.
      AppErrorCode.productOutOfStock ||
      AppErrorCode.stockLimit ||
      AppErrorCode.categoryInUse ||
      AppErrorCode.couponNotFound ||
      AppErrorCode.couponInactive ||
      AppErrorCode.couponExpired ||
      AppErrorCode.couponMinSpend ||
      AppErrorCode.couponUsageLimit =>
        _dataCarryingCodeFallback(context),
    };

/// A bare data-carrying code is a developer bug (the typed variants in
/// [localizedErrorMessage] are the only correct path). Surface it in debug
/// builds instead of silently degrading to the generic message.
String _dataCarryingCodeFallback(BuildContext context) {
  assert(false, 'data-carrying codes must use their typed error variants');
  return context.l10n.errorDatabase;
}

/// Maps any [AppError] to a localized message, using the typed-variant data
/// for parameterized messages and falling back to [errorTextForCode].
String localizedErrorMessage(BuildContext context, AppError error) =>
    switch (error) {
      ProductOutOfStockError(:final productName) =>
        context.l10n.errorProductOutOfStock(productName),
      StockLimitError(
        :final productName,
        :final stock,
        :final currentInCart,
      ) =>
        // Digits (stock, in-cart count) follow the active locale. The hint is
        // its own sentence (no punctuation coupling between strings): join
        // with a plain space so each part stays independently translatable
        // and RTL-safe.
        context.localizeDigits(
          currentInCart > 0
              ? '${context.l10n.errorStockLimit(stock, productName)} '
                  '${context.l10n.errorStockLimitHint(currentInCart)}'
              : context.l10n.errorStockLimit(stock, productName),
        ),
      CategoryInUseError(:final productCount) =>
        context.localizeDigits(context.l10n.errorCategoryInUse(productCount)),
      CouponNotFoundError(:final couponCode) =>
        context.l10n.errorCouponNotFound(couponCode),
      CouponInactiveError(:final couponCode) =>
        context.l10n.errorCouponInactive(couponCode),
      CouponExpiredError(:final couponCode) =>
        context.l10n.errorCouponExpired(couponCode),
      CouponMinSpendError(
        :final requiredCents,
        :final currentCents,
      ) =>
        // Cents are formatted for display — the ARB placeholders are strings.
        context.l10n.errorCouponMinSpend(
          context.formatCents(currentCents),
          context.formatCents(requiredCents),
        ),
      CouponUsageLimitError(:final couponCode, :final maxUses) =>
        // The cap renders in the active locale's digits (like prices). The
        // code is an identifier, so a code containing digits converts too
        // (e.g. SAVE10 → SAVE١٠) — accepted message-level tradeoff.
        context.localizeDigits(
          context.l10n.errorCouponUsageLimit(couponCode, maxUses),
        ),
      _ => errorTextForCode(context, error.code),
    };

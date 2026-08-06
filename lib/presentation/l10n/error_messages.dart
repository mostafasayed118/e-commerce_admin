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
      AppErrorCode.quantityMin => context.l10n.errorQuantityMin,
      AppErrorCode.cartEmpty => context.l10n.errorCartEmpty,
      AppErrorCode.invalidStatusTransition =>
        context.l10n.errorInvalidStatusTransition,
      AppErrorCode.nameRequired => context.l10n.nameRequired,
      AppErrorCode.phoneRequired => context.l10n.phoneRequired,
      AppErrorCode.addressRequired => context.l10n.addressRequired,
      AppErrorCode.pinFormat => context.l10n.pinFormatError,
      AppErrorCode.pinNotSet => context.l10n.pinNotSet,
      AppErrorCode.pinIncorrect => context.l10n.pinIncorrect,
      // Data-carrying codes are only reachable through their typed variants
      // (handled in [localizedErrorMessage]); a bare code has no data to
      // format, so fall back to the generic message rather than crash.
      AppErrorCode.productOutOfStock ||
      AppErrorCode.stockLimit ||
      AppErrorCode.categoryInUse =>
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
        // Hint is its own sentence (no punctuation coupling between strings):
        // join with a plain space so each part stays independently
        // translatable and RTL-safe.
        currentInCart > 0
            ? '${context.l10n.errorStockLimit(stock, productName)} '
                '${context.l10n.errorStockLimitHint(currentInCart)}'
            : context.l10n.errorStockLimit(stock, productName),
      CategoryInUseError(:final productCount) =>
        context.l10n.errorCategoryInUse(productCount),
      _ => errorTextForCode(context, error.code),
    };

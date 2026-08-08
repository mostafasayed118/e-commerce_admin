import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/entities/order.dart';
import '../../../core/error/app_error.dart';
import '../../../core/utils/order_receipt_pdf.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/snack_bar.dart';
import 'order_date_format.dart';
import 'status_visuals.dart';

/// Resolves an [Order] into the fully localized receipt the PDF builder
/// consumes. Every string is resolved in the *viewer's* locale here — money
/// via [L10nContext.formatCents], digits via [L10nContext.localizeDigits],
/// item names via [L10nContext.orderItemName] — so the builder in
/// `core/utils/order_receipt_pdf.dart` stays a pure layout pass (no
/// `BuildContext`, fully unit-testable). The same split as the CSV export.
ReceiptData buildOrderReceiptData(BuildContext context, Order order) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).languageCode;
  return ReceiptData(
    title: l10n.receiptTitle,
    // The order number is an identifier — rendered canonically in every
    // locale, like coupon codes (the convention the screens already follow).
    orderNumber: order.orderNumber,
    placed: order.createdAt == null
        ? ''
        : l10n.placedAt(
            formatOrderDateTime(order.createdAt!, locale: locale),
          ),
    statusField: l10n.status,
    statusLabel: orderStatusLabel(context, order.status),
    deliverTo: l10n.deliverTo,
    customerName: order.shipping.name,
    customerPhone: context.localizeDigits(order.shipping.phone),
    customerAddress: order.shipping.address,
    itemsTitle: l10n.items,
    lines: [
      for (final item in order.items)
        ReceiptItemLine(
          name: context.orderItemName(item),
          detail: context.orderItemDetail(item),
          amount: context.formatCents(item.lineTotalCents),
        ),
    ],
    subtotalLabel: l10n.subtotal,
    subtotal: context.formatCents(order.subtotalCents),
    savingsLabel: l10n.savings,
    savings: order.lineDiscountCents > 0
        ? context.formatCents(-order.lineDiscountCents)
        : null,
    couponLabel: order.couponDiscountCents > 0
        ? l10n.couponLabel(order.couponCode ?? '')
        : null,
    coupon: order.couponDiscountCents > 0
        ? context.formatCents(-order.couponDiscountCents)
        : null,
    totalLabel: l10n.total,
    total: context.formatCents(order.totalCents),
  );
}

/// Loads the receipt's base font for [locale]: the bundled Arabic TrueType
/// font under `ar` (pdf's built-in fonts are Latin-only — without it, Arabic
/// text cannot be encoded at all), the built-in Helvetica otherwise.
///
/// Takes the language code rather than a [BuildContext] so the caller can
/// resolve it synchronously (no context across the [rootBundle] await) and
/// tests can call it directly.
Future<pw.Font> loadReceiptFont(String locale) async {
  if (locale != 'ar') {
    return pw.Font.helvetica();
  }
  final data = await rootBundle.load(receiptArabicFontAsset);
  return pw.Font.ttf(data);
}

/// The shared Save-As export flow used by the **customer and admin** order
/// detail screens: native save dialog → the pure, unit-tested
/// [buildOrderReceiptPdf] → write → success/error SnackBar. Only the dialog
/// + write touch the platform (the same split as the admin CSV export), and
/// every context-dependent value is resolved up front so no `BuildContext`
/// use spans an async gap.
Future<void> exportOrderReceipt(BuildContext context, Order order) async {
  final l10n = context.l10n;
  final data = buildOrderReceiptData(context, order);
  final locale = Localizations.localeOf(context).languageCode;
  final font = await loadReceiptFont(locale);
  final rtl = locale == 'ar';
  try {
    final location = await getSaveLocation(
      suggestedName: 'receipt_${order.orderNumber.toLowerCase()}.pdf',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
    );
    if (location == null) return; // user cancelled the dialog
    if (!context.mounted) return;
    final bytes = await buildOrderReceiptPdf(data, font: font, rtl: rtl);
    await XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
    ).saveTo(location.path);
    if (context.mounted) {
      // The file name is an identifier — kept canonical like order numbers.
      final fileName = location.path.split(RegExp(r'[\\/]')).last;
      showSuccessSnackBar(context, l10n.receiptSaved(fileName));
    }
  } catch (error) {
    if (context.mounted) {
      showErrorSnackBar(
        context,
        ReceiptExportError(message: 'Could not export receipt', cause: error),
      );
    }
  }
}

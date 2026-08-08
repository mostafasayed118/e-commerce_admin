/// Order-confirmation receipt rendered as a PDF.
///
/// Layout only — every string arrives fully resolved (localized, digits
/// converted) in [ReceiptData], so this file stays a pure Dart layout pass
/// with no `BuildContext` or platform imports (the same split as the CSV
/// export: `core/utils/order_csv` serializes, the screen owns the dialog).
///
/// Text encoding notes that shape the tests:
///  * Built-in fonts (Helvetica, the `en` default) encode text as WinAnsi
///    bytes, so with [buildOrderReceiptPdf]'s `compress: false` the receipt's
///    content is directly readable in the saved bytes.
///  * TrueType fonts (the bundled Arabic font) encode text as glyph indices,
///    which are not recoverable from the bytes — the `ar` test therefore
///    asserts on structure + the embedded font's name instead.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The bundled Arabic TrueType font (OFL-1.1, Google Fonts). pdf's built-in
/// fonts are Latin-only, so Arabic receipts must embed this font; the
/// presentation layer loads it via `rootBundle` (core stays platform-free).
const String receiptArabicFontAsset = 'assets/fonts/Amiri-Regular.ttf';

/// One snapshot line item, fully localized by the caller.
class ReceiptItemLine {
  const ReceiptItemLine({
    required this.name,
    required this.detail,
    required this.amount,
  });

  /// The product's name in the viewer's locale.
  final String name;

  /// The quantity × unit-price (with per-unit discount) note.
  final String detail;

  /// The line total.
  final String amount;
}

/// The fully resolved receipt content — every field is already localized and
/// digit-converted by the caller (presentation/features/orders/order_receipt_data),
/// so the PDF builder never touches `BuildContext` or the active locale.
class ReceiptData {
  const ReceiptData({
    required this.title,
    required this.orderNumber,
    required this.placed,
    required this.statusField,
    required this.statusLabel,
    required this.deliverTo,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.itemsTitle,
    required this.lines,
    required this.subtotalLabel,
    required this.subtotal,
    required this.savingsLabel,
    this.savings,
    this.couponLabel,
    this.coupon,
    required this.totalLabel,
    required this.total,
  });

  /// Document title ("Order receipt" / "إيصال الطلب").
  final String title;

  /// The canonical order number — an identifier, never digit-converted.
  final String orderNumber;

  /// The full "Placed …" line, pre-formatted in the viewer's locale
  /// (`''` when the order has no timestamp).
  final String placed;

  /// The status-field label ("Status" / "الحالة").
  final String statusField;

  /// The localized status ("Pending" / "قيد الانتظار").
  final String statusLabel;

  /// The "Deliver to" section title.
  final String deliverTo;
  final String customerName;

  /// The phone, already converted to the viewer's digit shapes.
  final String customerPhone;
  final String customerAddress;

  /// The "Items" section title.
  final String itemsTitle;
  final List<ReceiptItemLine> lines;

  final String subtotalLabel;
  final String subtotal;

  /// Line-savings row; `null` hides the row (no line discounts).
  final String savingsLabel;
  final String? savings;

  /// Coupon row (label + amount); `null` hides the row (no coupon).
  final String? couponLabel;
  final String? coupon;

  final String totalLabel;
  final String total;
}

/// Builds the order-confirmation receipt as PDF bytes.
///
/// [font] defaults to the built-in Helvetica, which is Latin-only and correct
/// for English receipts. Arabic receipts must pass an embedded TrueType font
/// (e.g. `assets/fonts/Amiri-Regular.ttf`) — without one, Arabic text cannot
/// be encoded (the base font rejects non-WinAnsi characters).
///
/// [rtl] lays the document out right-to-left for Arabic; the pdf package
/// applies Arabic glyph shaping + bidi reordering to RTL text spans.
///
/// [compress] is exposed for tests: with stream compression off, the text of
/// built-in-font spans is stored as readable bytes, so tests can assert the
/// receipt's content directly (the production default keeps files small).
Future<Uint8List> buildOrderReceiptPdf(
  ReceiptData data, {
  pw.Font? font,
  bool rtl = false,
  bool compress = true,
}) async {
  final document = pw.Document(compress: compress);
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font ?? pw.Font.helvetica()),
      build: (context) => pw.Directionality(
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: _ReceiptBody(data: data, rtl: rtl),
      ),
    ),
  );
  return document.save();
}

/// The single-page receipt layout (A4).
class _ReceiptBody extends pw.StatelessWidget {
  _ReceiptBody({required this.data, required this.rtl});

  final ReceiptData data;
  final bool rtl;

  @override
  pw.Widget build(pw.Context context) {
    // Letter-spaced section headers only in LTR — Arabic glyphs are
    // connected, so tracking would break them (same rule as the app's UI).
    final tracking = rtl ? 0.0 : 1.2;
    return pw.Padding(
      padding: const pw.EdgeInsets.all(36),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // --- Header: title | order number -------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                data.title,
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                data.orderNumber,
                style: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          if (data.placed.isNotEmpty) ...[
            pw.Text(data.placed, style: _small),
            pw.SizedBox(height: 2),
          ],
          pw.Text(
            '${data.statusField}: ${data.statusLabel}',
            style: _small,
          ),
          _hairline(),

          // --- Deliver-to ---------------------------------------------------
          pw.Text(
            data.deliverTo,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: tracking,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(data.customerName, style: _body),
          pw.Text(data.customerPhone, style: _small),
          pw.Text(data.customerAddress, style: _small),
          _hairline(),

          // --- Items ----------------------------------------------------------
          pw.Text(
            data.itemsTitle,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: tracking,
            ),
          ),
          pw.SizedBox(height: 4),
          for (final line in data.lines) _lineRow(line),
          _hairline(),

          // --- Totals ---------------------------------------------------------
          _totalRow(data.subtotalLabel, data.subtotal),
          if (data.savings != null)
            _totalRow(data.savingsLabel, data.savings!),
          if (data.coupon != null)
            _totalRow(data.couponLabel!, data.coupon!),
          pw.Divider(height: 14, thickness: 0.8, color: PdfColors.grey500),
          _totalRow(data.totalLabel, data.total, emphasized: true),
        ],
      ),
    );
  }

  pw.Widget _lineRow(ReceiptItemLine line) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(line.name, style: _body),
                  pw.Text(line.detail, style: _small),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              line.amount,
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  pw.Widget _totalRow(
    String label,
    String amount, {
    bool emphasized = false,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: emphasized ? 12 : 10,
                fontWeight: emphasized ? pw.FontWeight.bold : null,
              ),
            ),
            pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: emphasized ? 12 : 10,
                fontWeight: emphasized ? pw.FontWeight.bold : null,
              ),
            ),
          ],
        ),
      );

  static final pw.TextStyle _body = pw.TextStyle(
    fontSize: 10,
    color: PdfColors.grey800,
  );

  static final pw.TextStyle _small = pw.TextStyle(
    fontSize: 8.5,
    color: PdfColors.grey600,
  );

  pw.Widget _hairline() => pw.Divider(
        height: 18,
        thickness: 0.5,
        color: PdfColors.grey400,
      );
}

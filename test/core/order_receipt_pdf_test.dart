import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:shop_admin/core/utils/order_receipt_pdf.dart';

/// A fully resolved English receipt (what the presentation assembly would
/// produce for the seeded-style order used across the suite).
const ReceiptData _enData = ReceiptData(
  title: 'Order receipt',
  orderNumber: 'ORD-000004',
  placed: 'Placed 1 Jul 2026, 06:00',
  statusField: 'Status',
  statusLabel: 'Pending',
  deliverTo: 'Deliver to',
  customerName: 'Omar Khaled',
  customerPhone: '0100 000 0004',
  customerAddress: '3 Zamalek St, Cairo',
  itemsTitle: 'Items',
  lines: [
    ReceiptItemLine(
      name: 'Yoga Mat',
      detail: '2 × \$26.10 (10% off)',
      amount: r'$52.20',
    ),
  ],
  subtotalLabel: 'Subtotal',
  subtotal: r'$59.00',
  savingsLabel: 'Savings',
  savings: r'-$6.00',
  couponLabel: 'Coupon (SAVE10)',
  coupon: r'-$3.00',
  totalLabel: 'Total',
  total: r'$50.00',
);

/// The same receipt in Arabic (Eastern digits, RTL), as the assembly would
/// resolve it for an `ar` viewer.
const ReceiptData _arData = ReceiptData(
  title: 'إيصال الطلب',
  orderNumber: 'ORD-000004',
  placed: 'تم الطلب في ١ يوليو ٢٠٢٦، ٠٦:٠٠',
  statusField: 'الحالة',
  statusLabel: 'قيد الانتظار',
  deliverTo: 'التوصيل إلى',
  customerName: 'عمر خالد',
  customerPhone: '٠١٠٠ ٠٠٠ ٠٠٠٤',
  customerAddress: '٣ شارع الزمالك، القاهرة',
  itemsTitle: 'العناصر',
  lines: [
    ReceiptItemLine(
      name: 'سجادة يوجا',
      detail: '٢ × ٢٦٫١٠ \$ (خصم ١٠٪)',
      amount: '٥٢٫٢٠ \$',
    ),
  ],
  subtotalLabel: 'المجموع الفرعي',
  subtotal: '٥٩٫٠٠ \$',
  savingsLabel: 'التوفير',
  savings: '-٦٫٠٠ \$',
  couponLabel: 'القسيمة (SAVE10)',
  coupon: '-٣٫٠٠ \$',
  totalLabel: 'الإجمالي',
  total: '٥٠٫٠٠ \$',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The built-in-font content stream stores text as WinAnsi bytes, so the
  // whole file decodes losslessly to ASCII-compatible text (no char > 0xFF
  // in the en case).
  String ascii(Uint8List bytes) => latin1.decode(bytes);

  test('builds a valid English receipt PDF with readable content', () async {
    final bytes = await buildOrderReceiptPdf(_enData, compress: false);

    expect(bytes, isNotEmpty);
    final text = ascii(bytes);
    expect(text, startsWith('%PDF-'));
    expect(text, contains('%%EOF'));

    // Built-in Helvetica encodes text as WinAnsi bytes, so the content is
    // directly readable — but pdf lays out each word as its own text run
    // (`(Yoga) (Mat) Tj …`), so multi-word strings are asserted word by
    // word. Parens in literal strings are escaped (`\(`), so paren-
    // containing text is asserted by its unescaped substrings.
    expect(text, contains('ORD-000004'));
    expect(text, contains('Yoga'));
    expect(text, contains('Mat'));
    expect(text, contains('Omar'));
    expect(text, contains('Khaled'));
    expect(text, contains('0100')); // phone
    expect(text, contains(r'$59.00')); // subtotal
    expect(text, contains(r'-$6.00')); // line savings
    expect(text, contains('SAVE10'));
    expect(text, contains(r'-$3.00')); // coupon amount
    expect(text, contains(r'$50.00')); // total
    expect(text, contains('10%'));
  });

  test('an empty placed line is omitted without breaking the document',
      () async {
    final data = ReceiptData(
      title: 'Order receipt',
      orderNumber: 'ORD-000001',
      placed: '',
      statusField: 'Status',
      statusLabel: 'Delivered',
      deliverTo: 'Deliver to',
      customerName: 'X',
      customerPhone: '0',
      customerAddress: 'Y',
      itemsTitle: 'Items',
      lines: const [],
      subtotalLabel: 'Subtotal',
      subtotal: r'$10.00',
      savingsLabel: 'Savings',
      totalLabel: 'Total',
      total: r'$10.00',
    );
    final bytes = await buildOrderReceiptPdf(data, compress: false);
    expect(ascii(bytes), contains('ORD-000001'));
  });

  test('builds an Arabic receipt embedding the Amiri TrueType font',
      () async {
    final font =
        pw.Font.ttf(await rootBundle.load(receiptArabicFontAsset));
    final bytes =
        await buildOrderReceiptPdf(_arData, font: font, rtl: true);

    expect(bytes, isNotEmpty);
    final text = ascii(bytes);
    expect(text, startsWith('%PDF-'));
    expect(text, contains('%%EOF'));
    // TTF text is emitted as glyph indices (not recoverable), but the
    // embedded font's PostScript name surfaces in the font descriptor.
    expect(text, contains('Amiri'));
  });

  test(
      'an Arabic receipt without an Arabic font builds but embeds no font '
      '(the glyphs are dropped, not written)', () async {
    // The built-in Helvetica cannot encode Arabic: pdf drops those glyphs
    // rather than throwing, so an ar receipt MUST be built with the bundled
    // Amiri font (the screen does via loadReceiptFont) or the Arabic content
    // silently disappears.
    final bytes = await buildOrderReceiptPdf(_arData, rtl: true);
    expect(ascii(bytes), isNot(contains('Amiri')));
  });
}

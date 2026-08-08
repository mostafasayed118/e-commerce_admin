import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../core/error/app_error.dart';
import '../../../core/utils/order_receipt_pdf.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/error_view.dart';
import '../../widgets/message_view.dart';
import '../../widgets/snack_bar.dart';
import 'order_detail_view.dart';
import 'order_receipt_data.dart';

/// Customer order detail: the full aggregate rendered by the shared
/// [OrderDetailView] (items, totals, shipping, status timeline). One read
/// stream → StreamBuilder, no Cubit (the same judgment as ProductDetail —
/// Section C.3). The AppBar carries the receipt-export action, gated on the
/// order being loaded (the export needs the aggregate).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  /// Writes the order's confirmation receipt to a PDF the user chooses via
  /// the native Save-As dialog. Only the dialog + write touch the platform —
  /// the bytes come from the pure, unit-tested [buildOrderReceiptPdf] (the
  /// same split as the admin CSV export).
  Future<void> _exportReceipt(BuildContext context, Order order) async {
    final l10n = context.l10n;
    // Everything context-dependent is resolved up front so no `BuildContext`
    // use spans an async gap (the dialog + write below are the only awaits).
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StreamBuilder<Order?>(
      stream: getIt<OrderRepository>().watchOrderById(orderId),
      builder: (context, snapshot) {
        final order = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.orderTitle),
            actions: [
              // Gated on the live stream so the action is inert while
              // loading/erroring or when the order is gone.
              if (order != null)
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: l10n.downloadReceipt,
                  onPressed: () => _exportReceipt(context, order),
                ),
            ],
          ),
          body: snapshot.hasError
              ? ErrorView(title: l10n.couldNotLoadOrder)
              : snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : order == null
                      ? MessageView(
                          icon: Icons.search_off,
                          title: l10n.orderNotFound,
                          message: l10n.orderRemoved,
                        )
                      : OrderDetailView(order: order),
        );
      },
    );
  }
}

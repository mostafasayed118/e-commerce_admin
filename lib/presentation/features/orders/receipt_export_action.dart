import 'package:flutter/material.dart';

import '../../../core/entities/order.dart';
import '../../l10n/l10n_ext.dart';
import 'order_receipt_data.dart';

/// The receipt-export AppBar action, shared by the **customer and admin**
/// order detail screens (the admin feature imports from here — the same
/// deliberate presentation-layer reuse as OrderDetailView): the download
/// icon, the localized tooltip, and the shared [exportOrderReceipt] flow in
/// one place, so both screens stay wired identically by construction.
///
/// Callers instantiate it only when an [Order] is actually loaded (the
/// screens gate it on their watch streams), keeping the action inert while
/// loading or erroring — the same gating the CSV export uses.
class ReceiptExportAction extends StatelessWidget {
  const ReceiptExportAction({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.download_outlined),
      tooltip: context.l10n.downloadReceipt,
      onPressed: () => exportOrderReceipt(context, order),
    );
  }
}

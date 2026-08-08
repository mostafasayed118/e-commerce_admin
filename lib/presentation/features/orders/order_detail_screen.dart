import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/error_view.dart';
import '../../widgets/message_view.dart';
import 'order_detail_view.dart';
import 'receipt_export_action.dart';

/// Customer order detail: the full aggregate rendered by the shared
/// [OrderDetailView] (items, totals, shipping, status timeline). One read
/// stream → StreamBuilder, no Cubit (the same judgment as ProductDetail —
/// Section C.3). The AppBar carries the receipt-export action (shared
/// [exportOrderReceipt], gated on the order being loaded).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

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
              if (order != null) ReceiptExportAction(order: order),
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

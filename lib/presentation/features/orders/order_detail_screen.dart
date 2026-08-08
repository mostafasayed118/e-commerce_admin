import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/error_view.dart';
import '../../widgets/message_view.dart';
import 'order_detail_view.dart';

/// Customer order detail: the full aggregate rendered by the shared
/// [OrderDetailView] (items, totals, shipping, status timeline). One read
/// stream → StreamBuilder, no Cubit (the same judgment as ProductDetail —
/// Section C.3).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderTitle)),
      body: StreamBuilder<Order?>(
        stream: getIt<OrderRepository>().watchOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(title: l10n.couldNotLoadOrder);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return MessageView(
              icon: Icons.search_off,
              title: l10n.orderNotFound,
              message: l10n.orderRemoved,
            );
          }
          return OrderDetailView(order: order);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: StreamBuilder<Order?>(
        stream: getIt<OrderRepository>().watchOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const MessageView(
              icon: Icons.error_outline,
              title: 'Could not load order',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return const MessageView(
              icon: Icons.search_off,
              title: 'Order not found',
              message: 'This order may have been removed.',
            );
          }
          return OrderDetailView(order: order);
        },
      ),
    );
  }
}

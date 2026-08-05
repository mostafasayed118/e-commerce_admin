import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order_status.dart';

void main() {
  group('OrderStatus.canTransitionTo', () {
    test('same-status moves are rejected for every status', () {
      for (final status in OrderStatus.values) {
        expect(status.canTransitionTo(status), isFalse,
            reason: 'no-op transition from $status');
      }
    });

    test('pending moves forward to confirmed, or sideways to cancelled', () {
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.confirmed), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.shipped), isFalse);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.delivered), isFalse);
    });

    test('confirmed moves forward to shipped, or sideways to cancelled', () {
      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.shipped), isTrue);
      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.pending), isFalse);
      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.delivered), isFalse);
    });

    test('shipped moves forward to delivered only', () {
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.delivered), isTrue);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.cancelled), isFalse);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.confirmed), isFalse);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.pending), isFalse);
    });

    test('delivered is terminal: no transitions out', () {
      for (final next in OrderStatus.values) {
        expect(OrderStatus.delivered.canTransitionTo(next), isFalse);
      }
    });

    test('cancelled is terminal: no transitions out', () {
      for (final next in OrderStatus.values) {
        expect(OrderStatus.cancelled.canTransitionTo(next), isFalse);
      }
    });
  });

  group('OrderStatus.canCancel', () {
    test('only pending and confirmed are cancellable', () {
      expect(OrderStatus.pending.canCancel, isTrue);
      expect(OrderStatus.confirmed.canCancel, isTrue);
      expect(OrderStatus.shipped.canCancel, isFalse);
      expect(OrderStatus.delivered.canCancel, isFalse);
      expect(OrderStatus.cancelled.canCancel, isFalse);
    });
  });

  group('OrderStatus.isTerminal', () {
    test('delivered and cancelled are terminal, others are not', () {
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
      expect(OrderStatus.pending.isTerminal, isFalse);
      expect(OrderStatus.confirmed.isTerminal, isFalse);
      expect(OrderStatus.shipped.isTerminal, isFalse);
    });
  });

  group('OrderStatus.label', () {
    test('provides human-readable labels', () {
      expect(OrderStatus.pending.label, 'Pending');
      expect(OrderStatus.confirmed.label, 'Confirmed');
      expect(OrderStatus.shipped.label, 'Shipped');
      expect(OrderStatus.delivered.label, 'Delivered');
      expect(OrderStatus.cancelled.label, 'Cancelled');
    });
  });
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/search_text.dart';
import '../../../../domain/repositories/order_repository.dart';
import 'admin_orders_state.dart';

export 'admin_orders_state.dart';

/// Non-digits, for order-number digit-run matching. Hoisted so
/// [_matchesQuery] — which runs per order per recompute — does not recompile
/// it on every call (same rationale as the tashkeel regex in search_text).
final RegExp _nonDigitRegExp = RegExp('[^0-9]');

/// Drives the admin order management screens: watch-driven list with a
/// client-side status filter, plus [updateStatus] which delegates to the
/// repository (whose `canTransitionTo` state machine rejects illegal moves —
/// the UI only *shows* legal ones, but the repository is the enforcement
/// boundary). The watch stream re-emits the updated aggregate afterwards.
class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit(this._orders) : super(const AdminOrdersLoading()) {
    _subscribe();
  }

  final OrderRepository _orders;

  bool _failed = false;
  OrderStatus? _filter;
  String _query = '';
  DateTime? _fromDate;

  /// The picked "to" calendar day (start of that day), kept for display and
  /// the picker's initial value; filtering uses [_toDateExclusive] instead.
  DateTime? _toDate;

  /// 00:00 of the day AFTER the picked "to" day — the exclusive upper bound.
  /// An order created at 23:59:59.500 still counts as within the day (a
  /// 23:59:59.999 upper bound would silently drop it).
  DateTime? _toDateExclusive;
  StreamSubscription<List<Order>>? _sub;

  void _subscribe() {
    _sub = _orders.watchOrders().listen(
      (orders) {
        if (_failed) return; // sticky error, as in the other feature cubits
        _recompute(orders);
      },
      onError: (Object error) {
        _failed = true;
        emit(const AdminOrdersError('Could not load orders'));
      },
    );
  }

  void _recompute(List<Order> orders) {
    final query = normalizeSearchText(_query.trim());
    emit(AdminOrdersLoaded(
      allOrders: orders,
      filter: _filter,
      query: _query,
      fromDate: _fromDate,
      toDate: _toDate,
      visibleOrders: orders
          .where((o) =>
              (_filter == null || o.status == _filter) &&
              _matchesQuery(o, query) &&
              _inDateRange(o))
          .toList(),
    ));
  }

  /// Order-number matching tolerates the padded format: 'ORD-1', 'ord1',
  /// '000001' and 'ORD-000001' all find 'ORD-000001'. Matching is against
  /// the hyphen-free number AND its digit run, so the pad is irrelevant.
  bool _matchesQuery(Order order, String query) {
    if (query.isEmpty) return true;
    final number = normalizeSearchText(order.orderNumber);
    final numberDigits = number.replaceAll(_nonDigitRegExp, '');
    final queryDigits = query.replaceAll(_nonDigitRegExp, '');
    return number.contains(query) ||
        number.replaceAll('-', '').contains(query.replaceAll('-', '')) ||
        // The digit-run path only when the query actually carries digits —
        // otherwise 'A' (a name query) would match every number via ''.
        (queryDigits.isNotEmpty && numberDigits.contains(queryDigits)) ||
        normalizeSearchText(order.shipping.name).contains(query) ||
        normalizeSearchText(order.shipping.phone).contains(query);
  }

  /// [fromDate] is inclusive from its start of day; the upper bound is
  /// [_toDateExclusive] (exclusive next-day start), so the whole "to" day
  /// counts. Orders without a [Order.createdAt] cannot be placed in a range,
  /// so an active date filter excludes them.
  bool _inDateRange(Order order) {
    final created = order.createdAt;
    if (_fromDate != null) {
      if (created == null || created.isBefore(_fromDate!)) return false;
    }
    if (_toDateExclusive != null) {
      if (created == null || !created.isBefore(_toDateExclusive!)) return false;
    }
    return true;
  }

  /// Applies the status filter; `null` clears it (shows all).
  void setFilter(OrderStatus? filter) {
    if (_failed) return;
    _filter = filter;
    final state = this.state;
    if (state is AdminOrdersLoaded) {
      _recompute(state.allOrders);
    }
  }

  /// Sets the free-text search (order number / customer name / phone).
  void setQuery(String query) {
    if (_failed) return;
    _query = query;
    final state = this.state;
    if (state is AdminOrdersLoaded) {
      _recompute(state.allOrders);
    }
  }

  /// Sets the inclusive [DateTime] range. Bounds are normalized here so the
  /// screen never worries about time-of-day: [from] snaps to its start of
  /// day, [to] becomes the exclusive start of the NEXT day (sub-second
  /// robust). The state's [AdminOrdersLoaded.toDate] keeps the picked
  /// calendar day for display. Pass `null` for either bound to clear it.
  void setDateRange({DateTime? from, DateTime? to}) {
    if (_failed) return;
    _fromDate = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    _toDate = to;
    _toDateExclusive = to == null
        ? null
        : DateTime(to.year, to.month, to.day + 1);
    final state = this.state;
    if (state is AdminOrdersLoaded) {
      _recompute(state.allOrders);
    }
  }

  /// Clears every filter (status, query, date range).
  void clearFilters() {
    if (_failed) return;
    _filter = null;
    _query = '';
    _fromDate = null;
    _toDate = null;
    _toDateExclusive = null;
    final state = this.state;
    if (state is AdminOrdersLoaded) {
      _recompute(state.allOrders);
    }
  }

  /// Delegates to the repository's transition validator. The returned
  /// [Result] feeds the detail screen's SnackBar; success re-emits the list
  /// automatically via the watch stream.
  Future<Result<Order>> updateStatus(int orderId, OrderStatus newStatus) =>
      _orders.updateStatus(orderId, newStatus);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/order_csv.dart';
import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/message_view.dart';
import '../../../widgets/responsive/content_max_width.dart';
import '../../orders/order_date_format.dart';
import '../../orders/order_list_tile.dart';
import '../../orders/status_visuals.dart';
import 'admin_orders_cubit.dart';

/// Admin order management: every order with a free-text search (order
/// number / customer / phone), a status filter chip row, and an inclusive
/// from/to date range; tap to open the detail (where status transitions
/// happen). DI-owned cubit provided by **value**.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminOrdersCubit>.value(
      value: getIt<AdminOrdersCubit>(),
      child: const _AdminOrdersView(),
    );
  }
}

class _AdminOrdersView extends StatelessWidget {
  const _AdminOrdersView();

  /// Writes the CURRENTLY FILTERED orders (what the admin sees) to a CSV the
  /// user chooses via the native save dialog. Only the dialog + write touch
  /// the platform — the serialization itself is the pure, unit-tested
  /// [ordersToCsvBytes].
  Future<void> _exportOrders(BuildContext context) async {
    final cubit = context.read<AdminOrdersCubit>();
    final state = cubit.state;
    if (state is! AdminOrdersLoaded || state.visibleOrders.isEmpty) return;
    final l10n = context.l10n;
    final location = await getSaveLocation(
      suggestedName: 'orders_${isoDate(DateTime.now())}.csv',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (location == null) return; // user cancelled the dialog
    await XFile.fromData(
      Uint8List.fromList(ordersToCsvBytes(state.visibleOrders)),
      mimeType: 'text/csv',
    ).saveTo(location.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            // The count follows the active locale's digits (Task 23).
            context.localizeDigits(l10n.exportDone(state.visibleOrders.length)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orders),
        actions: [
          // Gated on the live state so the action is inert (disabled) while
          // loading/erroring or when nothing is visible to export.
          BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
            builder: (context, state) {
              final canExport =
                  state is AdminOrdersLoaded && state.visibleOrders.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: l10n.exportOrders,
                onPressed: canExport ? () => _exportOrders(context) : null,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
        builder: (context, state) => switch (state) {
          AdminOrdersLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminOrdersError() => const ErrorView(),
          AdminOrdersLoaded() => _LoadedOrders(state: state),
        },
      ),
    );
  }
}

class _LoadedOrders extends StatefulWidget {
  const _LoadedOrders({required this.state});

  final AdminOrdersLoaded state;

  @override
  State<_LoadedOrders> createState() => _LoadedOrdersState();
}

class _LoadedOrdersState extends State<_LoadedOrders> {
  final TextEditingController _searchController = TextEditingController();

  /// Whether the field currently holds text — drives the one-tap clear (✕)
  /// affordance so it appears exactly while there is something to clear
  /// (same pattern as the catalog's LoadedCatalog).
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() => _hasSearchText = hasText);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  AdminOrdersLoaded get state => widget.state;

  void _clearSearch() {
    _searchController.clear();
    context.read<AdminOrdersCubit>().setQuery('');
  }

  /// Opens the date picker for one bound; keeps the other bound untouched.
  Future<void> _pickDate({required bool isFrom}) async {
    final cubit = context.read<AdminOrdersCubit>();
    final l10n = context.l10n;
    final now = DateTime.now();
    final yearEnd = DateTime(now.year, 12, 31);
    final initial =
        isFrom ? state.fromDate ?? state.toDate ?? now : state.toDate ?? state.fromDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // The other bound clamps this one, so a from > to range is impossible
      // to select (picking To can't go before From, and vice versa).
      firstDate: isFrom ? DateTime(2020) : state.fromDate ?? DateTime(2020),
      lastDate: isFrom ? state.toDate ?? yearEnd : yearEnd,
      helpText: isFrom ? l10n.fromDate : l10n.toDate,
    );
    if (picked == null) return;
    if (isFrom) {
      cubit.setDateRange(from: picked, to: state.toDate);
    } else {
      cubit.setDateRange(from: state.fromDate, to: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminOrdersCubit>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return ContentMaxWidth(
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: cubit.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchOrders,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.clearFilters,
                      // Compact so the 48dp default tap target does not
                      // inflate the dense field's height.
                      visualDensity: VisualDensity.compact,
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
          ),
        ),
        _FilterChips(
          selected: state.filter,
          onSelected: cubit.setFilter,
        ),
        _DateRangeRow(
          fromDate: state.fromDate,
          toDate: state.toDate,
          locale: locale,
          onPickFrom: () => _pickDate(isFrom: true),
          onPickTo: () => _pickDate(isFrom: false),
          onClear: state.fromDate == null && state.toDate == null
              ? null
              : () => cubit.setDateRange(from: null, to: null),
        ),
        Expanded(
          child: state.visibleOrders.isEmpty
              ? MessageView(
                  icon: Icons.search_off,
                  title: state.hasActiveFilter
                      ? l10n.noOrdersMatchTitle
                      : l10n.noOrdersTitle,
                  message: state.hasActiveFilter
                      ? l10n.noOrdersMatchMessage
                      : l10n.ordersWillAppear,
                  action: state.hasActiveFilter
                      ? TextButton(
                          onPressed: () {
                            _searchController.clear();
                            cubit.clearFilters();
                          },
                          child: Text(l10n.clearFilters),
                        )
                      : null,
                )
              : _OrderList(orders: state.visibleOrders),
        ),
      ],
      ),
    );
  }
}

/// The from/to date-range chips. [onClear] is `null` (and hidden) while no
/// bound is set — there is nothing to clear yet.
class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.fromDate,
    required this.toDate,
    required this.locale,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClear,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final String locale;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _dateChip(
            context,
            label: fromDate == null
                ? l10n.fromDate
                : '${l10n.fromDate}: ${formatOrderDate(fromDate!, locale: locale)}',
            onPressed: onPickFrom,
          ),
          const SizedBox(width: 8),
          _dateChip(
            context,
            label: toDate == null
                ? l10n.toDate
                : '${l10n.toDate}: ${formatOrderDate(toDate!, locale: locale)}',
            onPressed: onPickTo,
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onClear,
              child: Text(l10n.clearDates),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateChip(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      avatar: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          Padding(
            // Directional so the gap flips to the leading edge in RTL (Task 23).
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(context.l10n.all),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              showCheckmark: false,
            ),
          ),
          for (final status in OrderStatus.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(orderStatusLabel(context, status)),
                selected: selected == status,
                onSelected: (_) => onSelected(status),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) => OrderListTile(
        order: orders[index],
        onTap: () => context.push('/admin/orders/${orders[index].id}'),
      ),
    );
  }
}

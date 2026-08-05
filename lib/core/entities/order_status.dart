/// Lifecycle of an order. Stored in the DB as its enum index (drift intEnum).
///
/// The legal-move rules live here as a pure function so the state machine is
/// unit-testable in isolation and enforced from a single source of truth:
/// the order repository refuses illegal transitions using [canTransitionTo].
///
/// **Index stability contract:** drift's `intEnum` persists `index` values to
/// SQLite, so the declaration order below is permanent — only *append* new
/// statuses, never reorder or insert in the middle, or existing rows will
/// silently map to the wrong status. (A future change could switch to an
/// explicit int mapping to make reordering safe.)
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  /// Human-readable label for the UI.
  final String label;

  /// Whether an order in this status can legally move to [next].
  /// Same-status moves are rejected (no no-op transitions).
  bool canTransitionTo(OrderStatus next) {
    if (next == this) return false;
    return switch (this) {
      pending => next == confirmed || next == cancelled,
      confirmed => next == shipped || next == cancelled,
      shipped => next == delivered,
      delivered => false,
      cancelled => false,
    };
  }

  /// Whether cancellation is still allowed from this status.
  bool get canCancel => switch (this) {
        pending || confirmed => true,
        _ => false,
      };

  /// Terminal statuses: no further transitions are allowed.
  bool get isTerminal => this == delivered || this == cancelled;
}

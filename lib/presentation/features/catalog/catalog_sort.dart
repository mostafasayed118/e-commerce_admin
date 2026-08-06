import '../../../core/entities/product.dart';

/// Sort options for the catalog. The default is [newest] — the conventional
/// shop default; name is the tiebreak for every option so ordering is always
/// deterministic (important: the seed data shares one base timestamp, so
/// `newest` alone would be arbitrary).
enum CatalogSort {
  newest('Newest'),
  name('Name A-Z'),
  priceAsc('Price: low to high'),
  priceDesc('Price: high to low');

  const CatalogSort(this.label);

  final String label;

  /// Comparator for [List.sort]. Always falls back to name for a stable,
  /// deterministic total order.
  int compare(Product a, Product b) {
    final primary = switch (this) {
      CatalogSort.newest => (b.createdAt ?? _epoch)
          .compareTo(a.createdAt ?? _epoch),
      CatalogSort.name => _nameOf(a).compareTo(_nameOf(b)),
      CatalogSort.priceAsc => a.finalPriceCents.compareTo(b.finalPriceCents),
      CatalogSort.priceDesc => b.finalPriceCents.compareTo(a.finalPriceCents),
    };
    if (primary != 0) return primary;
    return _nameOf(a).compareTo(_nameOf(b));
  }

  // The sort key is deliberately the CANONICAL English name, not the
  // viewer-locale display name: sorting must be locale-independent and
  // deterministic, and the canonical text is always present.
  static String _nameOf(Product p) => p.name.toLowerCase();
  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
}

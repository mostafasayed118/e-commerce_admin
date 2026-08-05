/// Hand-rolled date formatting for orders.
///
/// Localization is explicitly out of scope for this project, and `intl`
/// would be a heavy dependency for two functions (Section D.3: defer it).
/// These formats are deliberately stable and simple.
library;

const List<String> _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// `DateTime(2026, 8, 5) -> "5 Aug 2026"`.
String formatOrderDate(DateTime date) =>
    '${date.day} ${_monthAbbr[date.month - 1]} ${date.year}';

/// `DateTime(2026, 8, 5, 9, 5) -> "5 Aug 2026, 09:05"` (for timeline entries).
String formatOrderDateTime(DateTime date) =>
    '${formatOrderDate(date)}, ${_two(date.hour)}:${_two(date.minute)}';

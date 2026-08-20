// Helpers for the shared `?month=YYYY-MM` queue filter. Pure Dart (no Flutter)
// so both the cubits (for the default scope) and the widgets (for the picker)
// can use them.

/// `YYYY-MM` for the current calendar month — the default scope for every queue.
String currentMonthKey() => _monthKey(DateTime.now());

/// The current month and the previous [count] − 1 months, newest first, as
/// `YYYY-MM` keys — the options offered by the month picker.
List<String> recentMonthKeys({int count = 12}) {
  final now = DateTime.now();
  return [
    for (var i = 0; i < count; i++)
      _monthKey(DateTime(now.year, now.month - i)),
  ];
}

String _monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

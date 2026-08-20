import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/core/utils/month_filter.dart';

/// The shared `?month=YYYY-MM` filter helpers that back the queue default scope.
void main() {
  final monthKey = RegExp(r'^\d{4}-\d{2}$');

  test('currentMonthKey matches the current calendar month, zero-padded', () {
    final now = DateTime.now();
    final expected = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    expect(currentMonthKey(), expected);
    expect(currentMonthKey(), matches(monthKey));
  });

  test('recentMonthKeys returns N keys, newest first, current month leading',
      () {
    final keys = recentMonthKeys(count: 12);
    expect(keys, hasLength(12));
    expect(keys.first, currentMonthKey());
    expect(keys.every(monthKey.hasMatch), isTrue);
    // Strictly descending (newest first), no duplicates.
    for (var i = 1; i < keys.length; i++) {
      expect(keys[i].compareTo(keys[i - 1]), lessThan(0), reason: keys[i]);
    }
  });

  test('a year boundary rolls the month back correctly', () {
    // 12 months back from any month lands on the same month one year earlier.
    final keys = recentMonthKeys(count: 13);
    final first = keys.first.split('-');
    final last = keys.last.split('-');
    expect(int.parse(last[0]), int.parse(first[0]) - 1);
    expect(last[1], first[1]); // same month, previous year
  });
}

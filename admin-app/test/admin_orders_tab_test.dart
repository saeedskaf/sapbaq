import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/admin_orders_cubit.dart';

void main() {
  group('adminOrdersTabFor', () {
    test('resolves every tab from its name', () {
      // The dashboard stat tiles deep-link with `tab.name`, so every tab must
      // survive the round-trip — otherwise a tile silently lands on the
      // default queue instead of the bucket it counted.
      for (final tab in AdminOrdersTab.values) {
        expect(adminOrdersTabFor(tab.name), tab);
      }
    });

    test('falls back to the awaiting working queue', () {
      expect(adminOrdersTabFor(null), AdminOrdersTab.awaiting);
      expect(adminOrdersTabFor(''), AdminOrdersTab.awaiting);
      expect(adminOrdersTabFor('not-a-tab'), AdminOrdersTab.awaiting);
    });

    test('is case-sensitive rather than guessing', () {
      expect(adminOrdersTabFor('PENDING'), AdminOrdersTab.awaiting);
    });
  });

  group('AdminOrdersCubit initial tab', () {
    test('defaults to awaiting', () {
      expect(const AdminOrdersState().tab, AdminOrdersTab.awaiting);
    });

    test('seeds the state so the first load is already filtered', () {
      // The cubit needs a repository to construct, so assert on the state the
      // dashboard's deep-link produces instead.
      expect(
        AdminOrdersState(tab: adminOrdersTabFor('delivered')).tab,
        AdminOrdersTab.delivered,
      );
    });
  });

  test('«الكل» stays the last tab (FLUTTER_TASKS item 9)', () {
    expect(AdminOrdersTab.values.last, AdminOrdersTab.all);
  });
}

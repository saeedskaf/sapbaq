import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';

/// The maintenance action matrix (FLUTTER_OPERATIONS_CENTER §4): each button
/// appears only when the role owns the action *and* the status allows it.
void main() {
  Set<MaintenanceAction> desk(String status) => visibleMaintenanceActions(
    status: status,
    isDesk: true,
    isLeader: false,
    canComplete: false,
  );

  group('dispatch desk sees the triage actions per status', () {
    test('SUBMITTED: acknowledge, approve, set-priority, cancel', () {
      expect(desk('SUBMITTED'), {
        MaintenanceAction.acknowledge,
        MaintenanceAction.approve,
        MaintenanceAction.setPriority,
        MaintenanceAction.cancel,
      });
    });

    test('ACKNOWLEDGED drops acknowledge, keeps the rest', () {
      expect(desk('ACKNOWLEDGED'), {
        MaintenanceAction.approve,
        MaintenanceAction.setPriority,
        MaintenanceAction.cancel,
      });
    });

    test('APPROVED: assign-team-leader + cancel only (no set-priority)', () {
      expect(desk('APPROVED'), {
        MaintenanceAction.assignLeader,
        MaintenanceAction.cancel,
      });
    });

    test('ASSIGNED/IN_PROGRESS: desk keeps only cancel', () {
      expect(desk('ASSIGNED'), {MaintenanceAction.cancel});
      expect(desk('IN_PROGRESS'), {MaintenanceAction.cancel});
    });

    test('COMPLETED: no desk actions (awaits verification, no cancel)', () {
      expect(desk('COMPLETED'), isEmpty);
    });

    test('terminal statuses expose nothing', () {
      for (final s in ['RESOLVED', 'CANCELLED', 'DUPLICATE']) {
        expect(desk(s), isEmpty, reason: s);
      }
    });
  });

  group('merge-duplicate (§3.1, customer channel only)', () {
    Set<MaintenanceAction> deskChannel(String status, bool customer) =>
        visibleMaintenanceActions(
          status: status,
          isDesk: true,
          isLeader: false,
          canComplete: false,
          isCustomerChannel: customer,
        );

    test('desk sees duplicate on a customer case at SUBMITTED/ACKNOWLEDGED', () {
      expect(
        deskChannel('SUBMITTED', true),
        contains(MaintenanceAction.duplicate),
      );
      expect(
        deskChannel('ACKNOWLEDGED', true),
        contains(MaintenanceAction.duplicate),
      );
    });

    test('never on a REP (non-customer) case', () {
      expect(
        deskChannel('SUBMITTED', false),
        isNot(contains(MaintenanceAction.duplicate)),
      );
    });

    test('not once the case is approved/dispatched', () {
      for (final s in ['APPROVED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED']) {
        expect(
          deskChannel(s, true),
          isNot(contains(MaintenanceAction.duplicate)),
          reason: s,
        );
      }
    });

    test('a non-desk role never sees duplicate, even on a customer case', () {
      expect(
        visibleMaintenanceActions(
          status: 'SUBMITTED',
          isDesk: false,
          isLeader: true,
          canComplete: true,
          isCustomerChannel: true,
        ),
        isNot(contains(MaintenanceAction.duplicate)),
      );
    });
  });

  group('team leader / handler actions', () {
    test('leader assigns a member and completes while in progress', () {
      final leader = visibleMaintenanceActions(
        status: 'ASSIGNED',
        isDesk: false,
        isLeader: true,
        canComplete: true,
      );
      expect(leader, {
        MaintenanceAction.assignMember,
        MaintenanceAction.complete,
      });
    });

    test('leader verifies a completed case', () {
      final leader = visibleMaintenanceActions(
        status: 'COMPLETED',
        isDesk: false,
        isLeader: true,
        canComplete: true,
      );
      expect(leader, {MaintenanceAction.verify});
    });

    test('assigned handler (not leader) can only complete', () {
      final handler = visibleMaintenanceActions(
        status: 'IN_PROGRESS',
        isDesk: false,
        isLeader: false,
        canComplete: true,
      );
      expect(handler, {MaintenanceAction.complete});
    });

    test('an unrelated role sees nothing', () {
      expect(
        visibleMaintenanceActions(
          status: 'ASSIGNED',
          isDesk: false,
          isLeader: false,
          canComplete: false,
        ),
        isEmpty,
      );
    });
  });

  group('claim (manager-direct §4.3)', () {
    Set<MaintenanceAction> leaderPulling(String status) =>
        visibleMaintenanceActions(
          status: status,
          isDesk: false,
          isLeader: false,
          canComplete: false,
          canClaim: true,
        );

    test('a team leader can claim an approved, unassigned case', () {
      expect(leaderPulling('APPROVED'), {MaintenanceAction.claim});
    });

    test('no other status is claimable', () {
      for (final s in [
        'SUBMITTED',
        'ACKNOWLEDGED',
        'ASSIGNED',
        'IN_PROGRESS',
        'COMPLETED',
        'RESOLVED',
        'CANCELLED',
      ]) {
        expect(leaderPulling(s), isEmpty, reason: s);
      }
    });

    test('claim is off by default, so the desk still only pushes', () {
      expect(desk('APPROVED'), {
        MaintenanceAction.assignLeader,
        MaintenanceAction.cancel,
      });
    });

    test('a desk user who is also a leader sees both pull and push', () {
      final both = visibleMaintenanceActions(
        status: 'APPROVED',
        isDesk: true,
        isLeader: false,
        canComplete: false,
        canClaim: true,
      );
      expect(both, {
        MaintenanceAction.claim,
        MaintenanceAction.assignLeader,
        MaintenanceAction.cancel,
      });
    });
  });
}

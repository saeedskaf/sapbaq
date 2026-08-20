import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';

/// The operations-center visibility/action matrix
/// (FLUTTER_OPERATIONS_CENTER §2–§3): who can moderate water flags, fulfil
/// contributions, moderate equipment, and triage maintenance. Locks in the
/// §3.3/§3.4 change that added the regional manager to water flags and
/// contributions without giving him the desk-only maintenance triage.
User _user(String type) => User(id: 1, phone: '', fullName: '', userType: type);

void main() {
  const desk = [User.retailOperator, User.supportAdmin];

  group('water-flag moderation (§3.3)', () {
    test('dispatch desk + regional manager + global admin can moderate', () {
      for (final t in [...desk, User.regionalManager, User.globalAdmin]) {
        expect(_user(t).canModerateWaterFlags, isTrue, reason: t);
      }
    });

    test('team leader and service handler cannot', () {
      for (final t in [User.teamLeader, User.serviceHandler]) {
        expect(_user(t).canModerateWaterFlags, isFalse, reason: t);
      }
    });
  });

  group('contribution fulfilment (§3.4)', () {
    test('desk, regional, team leader, handler, global can fulfil', () {
      for (final t in [
        ...desk,
        User.regionalManager,
        User.teamLeader,
        User.serviceHandler,
        User.globalAdmin,
      ]) {
        expect(_user(t).canFulfilContribution, isTrue, reason: t);
      }
    });
  });

  group('maintenance triage: desk + regional manager (unified-dispatch §4-b)', () {
    test('desk, regional manager, and global triage; leader/handler do not', () {
      for (final t in [...desk, User.regionalManager, User.globalAdmin]) {
        expect(_user(t).canTriageMaintenance, isTrue, reason: t);
      }
      for (final t in [User.teamLeader, User.serviceHandler]) {
        expect(_user(t).canTriageMaintenance, isFalse, reason: t);
      }
    });
  });

  group('equipment moderation (§3.2)', () {
    test('regional manager + global approve; desk only cancels', () {
      expect(_user(User.regionalManager).canApproveEquipment, isTrue);
      expect(_user(User.globalAdmin).canApproveEquipment, isTrue);
      for (final t in desk) {
        expect(_user(t).canApproveEquipment, isFalse, reason: t);
        expect(_user(t).canCancelEquipment, isTrue, reason: t);
      }
    });
  });

  group('manager direct provision', () {
    test('only the regional manager and global admin may provision', () {
      for (final t in [User.regionalManager, User.globalAdmin]) {
        expect(_user(t).canProvisionDirect, isTrue, reason: t);
      }
      for (final t in [...desk, User.teamLeader, User.serviceHandler]) {
        expect(_user(t).canProvisionDirect, isFalse, reason: t);
      }
    });

    test('only the team leader (and global admin) may claim a case', () {
      for (final t in [User.teamLeader, User.globalAdmin]) {
        expect(_user(t).canClaimMaintenance, isTrue, reason: t);
      }
      for (final t in [...desk, User.regionalManager, User.serviceHandler]) {
        expect(_user(t).canClaimMaintenance, isFalse, reason: t);
      }
    });

    test('provisioning and claiming are separate roles, never the same one', () {
      for (final t in [
        ...desk,
        User.regionalManager,
        User.teamLeader,
        User.serviceHandler,
      ]) {
        final u = _user(t);
        expect(
          u.canProvisionDirect && u.canClaimMaintenance,
          isFalse,
          reason: t,
        );
      }
    });
  });

  group('nearest-first location scope', () {
    test('only field roles are asked for their location', () {
      for (final t in [
        User.teamLeader,
        User.serviceHandler,
        User.globalAdmin,
      ]) {
        expect(_user(t).isFieldRole, isTrue, reason: t);
      }
      for (final t in [...desk, User.regionalManager]) {
        expect(_user(t).isFieldRole, isFalse, reason: t);
      }
    });
  });

  test('every role that can act on a queue can reach operations', () {
    for (final t in [
      ...desk,
      User.regionalManager,
      User.teamLeader,
      User.serviceHandler,
      User.globalAdmin,
    ]) {
      expect(_user(t).canAccessOperations, isTrue, reason: t);
    }
  });
}

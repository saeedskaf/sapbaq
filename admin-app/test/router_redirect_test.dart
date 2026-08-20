import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/app/router/app_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';

/// Redirect gating for [resolveAuthRedirect]. The focus is the mosque-rep
/// branch: the rep must reach the shared `/settings/...` screens (language +
/// appearance) his profile links to, without being bounced to the mosque tab.
void main() {
  const rep = User(
    id: 1,
    phone: '+965',
    fullName: 'Imam',
    userType: 'MOSQUE_REP',
  );
  const office = User(
    id: 2,
    phone: '+965',
    fullName: 'Staff',
    userType: 'GLOBAL_ADMIN',
  );
  const retail = User(
    id: 3,
    phone: '+965',
    fullName: 'Desk',
    userType: 'RETAIL_OPERATOR',
  );
  const handler = User(
    id: 4,
    phone: '+965',
    fullName: 'Field',
    userType: 'SERVICE_HANDLER',
  );

  String? redirectFor(User user, String location) => resolveAuthRedirect(
    status: AuthStatus.authenticated,
    user: user,
    location: location,
  );

  group('mosque rep', () {
    test('may open the shared language screen', () {
      expect(redirectFor(rep, AppRoutes.settingsLanguage), isNull);
    });

    test('may open the shared appearance screen', () {
      expect(redirectFor(rep, AppRoutes.settingsAppearance), isNull);
    });

    test('stays inside his own rep shell', () {
      expect(redirectFor(rep, AppRoutes.repProfile), isNull);
      expect(redirectFor(rep, AppRoutes.repReports), isNull);
    });

    test('is bounced out of staff areas to the mosque tab', () {
      expect(redirectFor(rep, AppRoutes.adminDashboard), AppRoutes.repMosque);
      expect(redirectFor(rep, AppRoutes.driverHome), AppRoutes.repMosque);
    });

    test('is bounced out of the operations center', () {
      expect(redirectFor(rep, AppRoutes.opsHub), AppRoutes.repMosque);
      expect(
        redirectFor(rep, AppRoutes.opsEquipmentRequests),
        AppRoutes.repMosque,
      );
    });

    test('is bounced out of the rep auth flow once authenticated', () {
      expect(redirectFor(rep, AppRoutes.repLogin), AppRoutes.repMosque);
    });
  });

  group('office staff', () {
    test('may still open the shared settings screens', () {
      expect(redirectFor(office, AppRoutes.settingsLanguage), isNull);
      expect(redirectFor(office, AppRoutes.settingsAppearance), isNull);
    });

    test('is kept out of the rep shell, landing on the dashboard', () {
      expect(
        redirectFor(office, AppRoutes.repMosque),
        AppRoutes.adminDashboard,
      );
    });

    test('lands on the dashboard after signing in', () {
      // The dashboard is the shell's first tab; the operations queues are a
      // tab away and their badge is visible from everywhere.
      expect(redirectFor(office, AppRoutes.splash), AppRoutes.adminDashboard);
      expect(redirectFor(office, AppRoutes.login), AppRoutes.adminDashboard);
    });

    test('may reach the operations center and its queues', () {
      expect(redirectFor(office, AppRoutes.adminOperations), isNull);
      expect(redirectFor(office, AppRoutes.opsHub), isNull);
      expect(redirectFor(office, AppRoutes.opsWaterFlags), isNull);
    });
  });

  group('operations-center access for shell-restricted roles', () {
    test('retail operator (dispatch desk) may reach the ops center', () {
      expect(redirectFor(retail, AppRoutes.opsHub), isNull);
      expect(redirectFor(retail, AppRoutes.opsMaintenance), isNull);
      // …but is still kept out of the full admin shell.
      expect(
        redirectFor(retail, AppRoutes.adminOrders),
        AppRoutes.retailCustomers,
      );
    });

    test('service handler may reach the ops center', () {
      expect(redirectFor(handler, AppRoutes.opsHub), isNull);
      expect(redirectFor(handler, AppRoutes.opsContributions), isNull);
      // …but is still kept out of the admin shell.
      expect(
        redirectFor(handler, AppRoutes.adminDashboard),
        AppRoutes.driverHome,
      );
    });

    test('each restricted shell carries its own operations tab', () {
      expect(redirectFor(retail, AppRoutes.retailOperations), isNull);
      expect(redirectFor(handler, AppRoutes.driverOperations), isNull);
    });

    test('the restricted roles never reach the admin shell tab', () {
      // `/admin/operations` is the same screen, but it lives in the admin
      // shell's tab bar — these roles use their own shells' tabs instead.
      expect(
        redirectFor(retail, AppRoutes.adminOperations),
        AppRoutes.retailCustomers,
      );
      expect(
        redirectFor(handler, AppRoutes.adminOperations),
        AppRoutes.driverHome,
      );
    });
  });

  group('session status', () {
    test('unknown status parks on splash', () {
      final r = resolveAuthRedirect(
        status: AuthStatus.unknown,
        user: null,
        location: AppRoutes.repProfile,
      );
      expect(r, AppRoutes.splash);
    });

    test('unauthenticated is sent to login (rep auth flow excepted)', () {
      expect(
        resolveAuthRedirect(
          status: AuthStatus.unauthenticated,
          user: null,
          location: AppRoutes.repProfile,
        ),
        AppRoutes.login,
      );
      expect(
        resolveAuthRedirect(
          status: AuthStatus.unauthenticated,
          user: null,
          location: AppRoutes.repLogin,
        ),
        isNull,
      );
    });
  });
}

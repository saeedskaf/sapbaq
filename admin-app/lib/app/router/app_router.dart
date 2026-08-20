import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/app/router/go_router_refresh_stream.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/activity_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/admin_order_detail_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/approvals_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/catalog_orders_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/contributions_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/direct_equipment_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/direct_maintenance_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/direct_provision_hub_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/direct_water_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/fulfilment_tasks_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/customer_lookup_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/equipment_requests_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/escalations_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/maintenance_detail_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/maintenance_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/operations_hub_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/products_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/water_flags_screen.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/admin_shell.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/driver_shell.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/rep_shell.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/retail_shell.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/auth/presentation/screens/login_screen.dart';
import 'package:sapbaq_admin/features/auth/presentation/screens/splash_screen.dart';
import 'package:sapbaq_admin/features/auth/presentation/screens/unauthorized_screen.dart';
import 'package:sapbaq_admin/features/driver/presentation/screens/driver_destination_detail_screen.dart';
import 'package:sapbaq_admin/features/driver/presentation/screens/driver_destinations_screen.dart';
import 'package:sapbaq_admin/features/driver/presentation/screens/upload_proof_screen.dart';
import 'package:sapbaq_admin/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sapbaq_admin/features/profile/presentation/screens/appearance_screen.dart';
import 'package:sapbaq_admin/features/profile/presentation/screens/language_screen.dart';
import 'package:sapbaq_admin/features/profile/presentation/screens/profile_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_equipment_form_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_forgot_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_invite_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_login_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_mosque_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_passcode_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_pending_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_register_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_report_form_screen.dart';
import 'package:sapbaq_admin/features/rep/presentation/screens/rep_reports_screen.dart';

int _idOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

/// Pure redirect decision for [createRouter] — factored out so the role gating
/// can be unit-tested without standing up an [AuthBloc]. Returns the location
/// to redirect to, or null to stay on [location].
String? resolveAuthRedirect({
  required AuthStatus status,
  required User? user,
  required String location,
}) {
  final atSplash = location == AppRoutes.splash;
  final atLogin = location == AppRoutes.login;
  final atUnauthorized = location == AppRoutes.unauthorized;

  // Public rep onboarding/login flow (self-registration, invite, recovery).
  final inRepAuthFlow = location.startsWith('/rep-auth');

  if (status == AuthStatus.unknown) {
    return atSplash ? null : AppRoutes.splash;
  }
  if (status == AuthStatus.unauthenticated) {
    return (atLogin || inRepAuthFlow) ? null : AppRoutes.login;
  }

  // Authenticated — route by role. The mosque representative gets his own
  // report-only shell; a signed-in customer (or an unresolved role) isn't
  // allowed in this app.
  if (user != null && user.isMosqueRep) {
    final inRepShell = location.startsWith('/rep');
    // The rep's profile links to the shared language/appearance screens
    // (`/settings/...`); allow those too, otherwise the redirect bounces
    // him back to the mosque tab and the settings never open.
    final inSharedSettings = location.startsWith('/settings/');
    if ((!inRepShell && !inSharedSettings) || inRepAuthFlow) {
      return AppRoutes.repMosque;
    }
    return null;
  }
  if (user == null || !user.isStaff) {
    return atUnauthorized ? null : AppRoutes.unauthorized;
  }

  final inAuthFlow = atSplash || atLogin || atUnauthorized || inRepAuthFlow;
  // Retail operator (LV3): restricted to its own customer-search + profile
  // shell. Keep it out of the full admin/driver areas (T1). The read-only
  // order detail (`/admin/order/:id`) stays reachable from a search result.
  if (user.isRetailOperator) {
    final inAdminShell =
        location.startsWith('/admin/') && !location.startsWith('/admin/order/');
    if (inAuthFlow ||
        inAdminShell ||
        location.startsWith('/driver') ||
        location.startsWith('/rep')) {
      return AppRoutes.retailCustomers;
    }
    return null;
  }
  if (user.isOfficeStaff) {
    if (inAuthFlow ||
        location.startsWith('/driver') ||
        location.startsWith('/retail') ||
        location.startsWith('/rep')) {
      // Land on the dashboard — the shell's first tab; the operations queues
      // are one tab away and their badge is visible from everywhere.
      return AppRoutes.adminDashboard;
    }
    return null;
  }
  // service handler (workshop)
  if (inAuthFlow ||
      location.startsWith('/admin') ||
      location.startsWith('/retail') ||
      location.startsWith('/rep')) {
    return AppRoutes.driverHome;
  }
  return null;
}

/// Builds the app router. Redirects are driven by [AuthBloc] state:
/// unknown → splash, unauthenticated → login, then by role: office/back-office
/// staff → admin shell, SERVICE_HANDLER → driver shell, anything else (customer,
/// MOSQUE_REP, unresolved) → unauthorized.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) => resolveAuthRedirect(
      status: authBloc.state.status,
      user: authBloc.state.user,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        name: AppRoutes.unauthorizedName,
        builder: (_, _) => const UnauthorizedScreen(),
      ),

      // Mosque-representative auth flow (public).
      GoRoute(
        path: AppRoutes.repLogin,
        name: AppRoutes.repLoginName,
        builder: (_, _) => const RepLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.repPasscode,
        name: AppRoutes.repPasscodeName,
        // The phone entered in step one arrives as `extra` (kept off the URL
        // so the number never lands in route params).
        builder: (_, state) =>
            RepPasscodeScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: AppRoutes.repRegister,
        name: AppRoutes.repRegisterName,
        builder: (_, _) => const RepRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.repInvite,
        name: AppRoutes.repInviteName,
        builder: (_, state) =>
            RepInviteScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: AppRoutes.repForgot,
        name: AppRoutes.repForgotName,
        builder: (_, _) => const RepForgotScreen(),
      ),
      GoRoute(
        path: AppRoutes.repPending,
        name: AppRoutes.repPendingName,
        builder: (_, _) => const RepPendingScreen(),
      ),

      // Rep full-screen routes (over the rep shell).
      GoRoute(
        path: AppRoutes.repReportForm,
        name: AppRoutes.repReportFormName,
        builder: (_, _) => const RepReportFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.repEquipmentForm,
        name: AppRoutes.repEquipmentFormName,
        builder: (_, _) => const RepEquipmentFormScreen(),
      ),

      // Language settings — pushed over any role's profile shell.
      GoRoute(
        path: AppRoutes.settingsLanguage,
        name: AppRoutes.settingsLanguageName,
        builder: (_, _) => const LanguageScreen(),
      ),

      // Appearance (light/dark) settings — pushed over any role's profile shell.
      GoRoute(
        path: AppRoutes.settingsAppearance,
        name: AppRoutes.settingsAppearanceName,
        builder: (_, _) => const AppearanceScreen(),
      ),

      // Operations center — the staff moderation hub and its queues. Neutral
      // `/ops` prefix so every staff role reaches it (the rep is redirected
      // out); each screen further gates its actions by role.
      GoRoute(
        path: AppRoutes.opsHub,
        name: AppRoutes.opsHubName,
        builder: (_, _) => const OperationsHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsWaterFlags,
        name: AppRoutes.opsWaterFlagsName,
        builder: (_, _) => const WaterFlagsScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsEquipmentRequests,
        name: AppRoutes.opsEquipmentRequestsName,
        builder: (_, _) => const EquipmentRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsMaintenance,
        name: AppRoutes.opsMaintenanceName,
        builder: (_, _) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsMaintenanceDetail,
        name: AppRoutes.opsMaintenanceDetailName,
        builder: (_, state) => MaintenanceDetailScreen(caseId: _idOf(state)),
      ),
      GoRoute(
        path: AppRoutes.opsContributions,
        name: AppRoutes.opsContributionsName,
        builder: (_, _) => const ContributionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsFulfilmentTasks,
        name: AppRoutes.opsFulfilmentTasksName,
        builder: (_, _) => const FulfilmentTasksScreen(),
      ),

      GoRoute(
        path: AppRoutes.opsCatalogOrders,
        name: AppRoutes.opsCatalogOrdersName,
        builder: (_, _) => const CatalogOrdersScreen(),
      ),

      // Manager direct provision. Entry points are role-gated in the UI and
      // every creation endpoint re-checks the role and governorate (403).
      GoRoute(
        path: AppRoutes.opsDirect,
        name: AppRoutes.opsDirectName,
        builder: (_, _) => const DirectProvisionHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsDirectWater,
        name: AppRoutes.opsDirectWaterName,
        builder: (_, _) => const DirectWaterScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsDirectEquipment,
        name: AppRoutes.opsDirectEquipmentName,
        builder: (_, _) => const DirectEquipmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.opsDirectMaintenance,
        name: AppRoutes.opsDirectMaintenanceName,
        builder: (_, _) => const DirectMaintenanceScreen(),
      ),

      // Admin full-screen routes (over the shell).
      GoRoute(
        path: AppRoutes.adminOrderDetail,
        name: AppRoutes.adminOrderDetailName,
        builder: (_, state) => AdminOrderDetailScreen(orderId: _idOf(state)),
      ),
      GoRoute(
        path: AppRoutes.adminActivity,
        name: AppRoutes.adminActivityName,
        builder: (_, _) => const ActivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCustomerLookup,
        name: AppRoutes.adminCustomerLookupName,
        builder: (_, _) => const CustomerLookupScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminApprovals,
        name: AppRoutes.adminApprovalsName,
        builder: (_, _) => const ApprovalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEscalations,
        name: AppRoutes.adminEscalationsName,
        builder: (_, _) => const EscalationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProducts,
        name: AppRoutes.adminProductsName,
        builder: (_, _) => const ProductsScreen(),
      ),

      // Driver full-screen routes (over the shell).
      GoRoute(
        path: AppRoutes.driverDestination,
        name: AppRoutes.driverDestinationName,
        builder: (_, state) =>
            DriverDestinationDetailScreen(destinationId: _idOf(state)),
      ),
      GoRoute(
        path: AppRoutes.driverProof,
        name: AppRoutes.driverProofName,
        builder: (_, state) => UploadProofScreen(destinationId: _idOf(state)),
      ),

      // Admin shell (Dashboard / Operations / Orders / Notifications /
      // Profile).
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminDashboard,
                name: AppRoutes.adminDashboardName,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminOperations,
                name: AppRoutes.adminOperationsName,
                builder: (_, _) => const OperationsHubScreen(isTab: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminOrders,
                name: AppRoutes.adminOrdersName,
                builder: (_, state) {
                  final tab =
                      state.uri.queryParameters[AppRoutes.adminOrdersTabQuery];
                  // Keyed by `?tab=` so arriving from a different stat tile
                  // rebuilds the screen (and its cubit) on the new filter
                  // instead of reusing the branch's existing state.
                  return AdminOrdersScreen(
                    key: ValueKey(tab),
                    initialTab: adminOrdersTabFor(tab),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminNotifications,
                name: AppRoutes.adminNotificationsName,
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminProfile,
                name: AppRoutes.adminProfileName,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Retail-operator shell (Customer Search / Operations / Profile) — T1.
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            RetailShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.retailCustomers,
                name: AppRoutes.retailCustomersName,
                builder: (_, _) => const CustomerLookupScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.retailOperations,
                name: AppRoutes.retailOperationsName,
                builder: (_, _) => const OperationsHubScreen(isTab: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.retailProfile,
                name: AppRoutes.retailProfileName,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Mosque-representative shell (My Mosque / Reports / Notifications /
      // Profile).
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            RepShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.repMosque,
                name: AppRoutes.repMosqueName,
                builder: (_, _) => const RepMosqueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.repReports,
                name: AppRoutes.repReportsName,
                builder: (_, state) => RepReportsScreen(
                  initialTab: repReportsTabIndex(
                    state.uri.queryParameters[AppRoutes.repReportsTabQuery],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.repNotifications,
                name: AppRoutes.repNotificationsName,
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.repProfile,
                name: AppRoutes.repProfileName,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Driver shell (Deliveries / Operations / Notifications / Profile).
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            DriverShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverHome,
                name: AppRoutes.driverHomeName,
                builder: (_, _) => const DriverDestinationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverOperations,
                name: AppRoutes.driverOperationsName,
                builder: (_, _) => const OperationsHubScreen(isTab: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverNotifications,
                name: AppRoutes.driverNotificationsName,
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverProfile,
                name: AppRoutes.driverProfileName,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

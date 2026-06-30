import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/app/router/go_router_refresh_stream.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/activity_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/admin_order_detail_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/approvals_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/customer_lookup_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/escalations_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/products_screen.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/admin_shell.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/driver_shell.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/retail_shell.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/auth/presentation/screens/login_screen.dart';
import 'package:sapbaq_admin/features/auth/presentation/screens/splash_screen.dart';
import 'package:sapbaq_admin/features/auth/presentation/screens/unauthorized_screen.dart';
import 'package:sapbaq_admin/features/driver/presentation/screens/driver_destination_detail_screen.dart';
import 'package:sapbaq_admin/features/driver/presentation/screens/driver_destinations_screen.dart';
import 'package:sapbaq_admin/features/driver/presentation/screens/upload_proof_screen.dart';
import 'package:sapbaq_admin/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sapbaq_admin/features/profile/presentation/screens/profile_screen.dart';

int _idOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

/// Builds the app router. Redirects are driven by [AuthBloc] state:
/// unknown → splash, unauthenticated → login, then by role: office/back-office
/// staff → admin shell, SERVICE_HANDLER → driver shell, anything else (customer,
/// MOSQUE_REP, unresolved) → unauthorized.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final status = authState.status;
      final user = authState.user;
      final location = state.matchedLocation;
      final atSplash = location == AppRoutes.splash;
      final atLogin = location == AppRoutes.login;
      final atUnauthorized = location == AppRoutes.unauthorized;

      if (status == AuthStatus.unknown) {
        return atSplash ? null : AppRoutes.splash;
      }
      if (status == AuthStatus.unauthenticated) {
        return atLogin ? null : AppRoutes.login;
      }

      // Authenticated — route by role. A signed-in customer (or an account
      // whose role couldn't be resolved) isn't allowed in this app.
      if (user == null || !user.isStaff) {
        return atUnauthorized ? null : AppRoutes.unauthorized;
      }

      final inAuthFlow = atSplash || atLogin || atUnauthorized;
      // Retail operator (LV3): restricted to its own customer-search + profile
      // shell. Keep it out of the full admin/driver areas (T1). The read-only
      // order detail (`/admin/order/:id`) stays reachable from a search result.
      if (user.isRetailOperator) {
        final inAdminShell =
            location.startsWith('/admin/') &&
            !location.startsWith('/admin/order/');
        if (inAuthFlow || inAdminShell || location.startsWith('/driver')) {
          return AppRoutes.retailCustomers;
        }
        return null;
      }
      if (user.isOfficeStaff) {
        if (inAuthFlow ||
            location.startsWith('/driver') ||
            location.startsWith('/retail')) {
          return AppRoutes.adminDashboard;
        }
        return null;
      }
      // service handler (workshop)
      if (inAuthFlow ||
          location.startsWith('/admin') ||
          location.startsWith('/retail')) {
        return AppRoutes.driverHome;
      }
      return null;
    },
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

      // Admin shell (Dashboard / Orders / Notifications / Profile).
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
                path: AppRoutes.adminOrders,
                name: AppRoutes.adminOrdersName,
                builder: (_, _) => const AdminOrdersScreen(),
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

      // Retail-operator shell (Customer Search / Profile) — T1.
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
                path: AppRoutes.retailProfile,
                name: AppRoutes.retailProfileName,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Driver shell (Deliveries / Notifications / Profile).
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

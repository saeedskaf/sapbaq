import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/app/router/go_router_refresh_stream.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/admin_order_detail_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/assign_screen.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/admin_shell.dart';
import 'package:sapbaq_admin/features/app_shell/presentation/driver_shell.dart';
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
/// unknown → splash, unauthenticated → login, then by role:
/// ADMIN → admin shell, DRIVER → driver shell, anything else → unauthorized.
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
      if (user.isAdmin) {
        if (inAuthFlow || location.startsWith('/driver')) {
          return AppRoutes.adminOrders;
        }
        return null;
      }
      // driver
      if (inAuthFlow || location.startsWith('/admin')) {
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
        path: AppRoutes.adminAssign,
        name: AppRoutes.adminAssignName,
        builder: (_, state) => AssignScreen(orderId: _idOf(state)),
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

      // Admin shell (Orders / Notifications / Profile).
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
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

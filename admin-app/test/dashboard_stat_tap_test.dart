import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';
import 'package:sapbaq_admin/core/theme/app_theme.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order_counts.dart';
import 'package:sapbaq_admin/features/admin/data/models/dashboard_summary.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:sapbaq_admin/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Records the filters the orders list asks the API for, so a tap can be
/// checked against the query it actually produces.
class _FakeAdminRepository implements AdminRepository {
  final List<({String? status, bool? awaiting, String? bucket})> orderQueries =
      [];

  @override
  Future<DashboardSummary> fetchDashboard() async => const DashboardSummary(
    orders: DashboardOrders(
      newOrders: 3,
      awaitingAssignment: 5,
      assigned: 2,
      completed: 7,
      cancelled: 1,
      all: 18,
    ),
  );

  @override
  Future<PaginatedResponse<AdminOrderSummary>> fetchOrders({
    int page = 1,
    String? status,
    bool? awaitingAssignment,
    String? bucket,
    int? mosque,
    int? workshop,
    String? search,
    String? code,
    String? ordering,
    ({double lat, double lng})? at,
  }) async {
    orderQueries.add((
      status: status,
      awaiting: awaitingAssignment,
      bucket: bucket,
    ));
    return const PaginatedResponse(count: 0, results: []);
  }

  @override
  Future<AdminOrderCounts> fetchCounts({
    String? search,
    int? mosque,
    int? workshop,
  }) async => const AdminOrderCounts();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Mirrors the real admin shell: dashboard and orders live in separate branches
/// of an [StatefulShellRoute.indexedStack], so each branch keeps its state
/// across tab switches. That persistence is what the `?tab=` key has to defeat,
/// so a router without it would not exercise the real behaviour.
GoRouter _router() {
  return GoRouter(
    initialLocation: AppRoutes.adminDashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => navigationShell,
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
                builder: (_, state) {
                  final tab =
                      state.uri.queryParameters[AppRoutes.adminOrdersTabQuery];
                  return AdminOrdersScreen(
                    key: ValueKey(tab),
                    initialTab: adminOrdersTabFor(tab),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _app(_FakeAdminRepository repo, GoRouter router) {
  return MultiRepositoryProvider(
    providers: [RepositoryProvider<AdminRepository>.value(value: repo)],
    child: BlocProvider(
      create: (_) => AuthBloc(_FakeAuthRepository()),
      child: MaterialApp.router(
        routerConfig: router,
        // The screens read colors through the ThemeColors extension.
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

void main() {
  testWidgets('every stat tile opens the orders list on its own bucket', (
    tester,
  ) async {
    // label shown on the tile -> the filter the orders list must then request.
    final cases = <String, ({String? status, bool? awaiting, String? bucket})>{
      'New': (status: 'PENDING', awaiting: null, bucket: null),
      'Awaiting assignment': (status: null, awaiting: true, bucket: null),
      'Confirmed': (status: 'CONFIRMED', awaiting: null, bucket: null),
      'Completed': (status: 'DELIVERED', awaiting: null, bucket: null),
      'Cancelled': (status: 'CANCELLED', awaiting: null, bucket: null),
      'Total': (status: null, awaiting: null, bucket: null),
    };

    for (final entry in cases.entries) {
      final repo = _FakeAdminRepository();
      await tester.pumpWidget(_app(repo, _router()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();

      expect(
        find.byType(AdminOrdersScreen),
        findsOneWidget,
        reason: 'tapping "${entry.key}" should open the orders list',
      );
      expect(
        repo.orderQueries.single,
        entry.value,
        reason: 'tapping "${entry.key}" should filter to its own bucket',
      );
    }
  });

  testWidgets('a second tile tap re-filters instead of reusing the last tab', (
    tester,
  ) async {
    // The orders route lives in a shell branch that survives navigation, so
    // without the `?tab=` key the screen would keep its first filter.
    final repo = _FakeAdminRepository();
    final router = _router();
    await tester.pumpWidget(_app(repo, router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(repo.orderQueries.last.status, 'CANCELLED');

    router.go(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(repo.orderQueries.last.status, 'DELIVERED');
  });
}

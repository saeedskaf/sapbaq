import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_router.dart';
import 'package:sapbaq_admin/core/constants/app_constants.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/notifications/push_notification_service.dart';
import 'package:sapbaq_admin/core/theme/app_theme.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Root of the Sapbaq Admin & Driver app. Provides the shared repositories and
/// the app-wide [AuthBloc], then runs a role-driven router (admin / driver).
class SapbaqAdminApp extends StatefulWidget {
  final Dio dio;
  final AuthRepository authRepository;
  final PushNotificationService pushNotifications;

  const SapbaqAdminApp({
    super.key,
    required this.dio,
    required this.authRepository,
    required this.pushNotifications,
  });

  @override
  State<SapbaqAdminApp> createState() => _SapbaqAdminAppState();
}

class _SapbaqAdminAppState extends State<SapbaqAdminApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  StreamSubscription<AuthState>? _authStatusSub;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(widget.authRepository)
      ..add(const AuthSubscriptionRequested());
    _router = createRouter(_authBloc);

    // Deep-link a tapped notification once the session is authenticated (§14):
    // a cold launch resolves auth asynchronously, so wait for it; runtime taps
    // fire the pendingRoute listener directly.
    _authStatusSub = _authBloc.stream.listen((state) {
      if (state.status == AuthStatus.authenticated) _maybeNavigatePending();
    });
    widget.pushNotifications.pendingRoute.addListener(_maybeNavigatePending);
  }

  void _maybeNavigatePending() {
    final route = widget.pushNotifications.pendingRoute.value;
    if (route == null) return;
    if (_authBloc.state.status != AuthStatus.authenticated) return;
    widget.pushNotifications.pendingRoute.value = null;
    // Defer a frame so the router has settled on the authenticated shell.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.pushNamed(route.name, pathParameters: route.pathParameters);
    });
  }

  @override
  void dispose() {
    _authStatusSub?.cancel();
    widget.pushNotifications.pendingRoute.removeListener(_maybeNavigatePending);
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Arabic-only app. Locale is fixed to 'ar' so layout is always RTL.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider<AdminRepository>(
          create: (_) => AdminRepository(widget.dio),
        ),
        RepositoryProvider<DriverRepository>(
          create: (_) => DriverRepository(widget.dio),
        ),
        RepositoryProvider<NotificationsRepository>(
          create: (_) => NotificationsRepository(widget.dio),
        ),
      ],
      child: BlocProvider.value(
        value: _authBloc,
        child: MaterialApp.router(
          title: 'Sapbaq Admin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale(AppConstants.languageCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      ),
    );
  }
}

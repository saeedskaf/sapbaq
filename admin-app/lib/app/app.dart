import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_router.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/notifications/push_notification_service.dart';
import 'package:sapbaq_admin/core/settings/settings_cubit.dart';
import 'package:sapbaq_admin/core/settings/settings_service.dart';
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
  final SettingsService settingsService;
  final ValueNotifier<String> languageCode;
  final PushNotificationService pushNotifications;

  const SapbaqAdminApp({
    super.key,
    required this.dio,
    required this.authRepository,
    required this.settingsService,
    required this.languageCode,
    required this.pushNotifications,
  });

  @override
  State<SapbaqAdminApp> createState() => _SapbaqAdminAppState();
}

class _SapbaqAdminAppState extends State<SapbaqAdminApp> {
  late final AuthBloc _authBloc;
  late final SettingsCubit _settingsCubit;
  late final GoRouter _router;
  StreamSubscription<AuthState>? _authStatusSub;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(widget.authRepository)
      ..add(const AuthSubscriptionRequested());
    _settingsCubit = SettingsCubit(
      service: widget.settingsService,
      languageCode: widget.languageCode,
    );
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
    _settingsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _settingsCubit),
        ],
        // Rebuild on a language switch so MaterialApp adopts the new locale
        // (and flips RTL/LTR) without a restart. The listener also re-applies
        // the Android notification channel's localized name, which is what the
        // user sees in the system notification settings.
        child: BlocListener<SettingsCubit, SettingsState>(
          listenWhen: (a, b) => a.locale != b.locale,
          listener: (_, settings) => widget.pushNotifications
              .updateChannelLocalization(settings.locale),
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settings) {
              return MaterialApp.router(
                title: 'Sapbaq Admin',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: settings.themeMode,
                locale: settings.locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: _router,
                // Sensible status-bar icon brightness for screens without an
                // AppBar (splash); AppBar screens still override this.
                builder: (context, child) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: isDark
                        ? AppTheme.statusBarStyleDark
                        : AppTheme.statusBarStyleLight,
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

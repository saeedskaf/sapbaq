import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_router.dart';
import 'package:sapbaq_admin/core/location/location_service.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/notifications/notification_deep_link.dart';
import 'package:sapbaq_admin/core/notifications/push_notification_service.dart';
import 'package:sapbaq_admin/core/settings/settings_cubit.dart';
import 'package:sapbaq_admin/core/settings/settings_service.dart';
import 'package:sapbaq_admin/core/theme/app_theme.dart';
import 'package:sapbaq_admin/core/widgets/dismiss_keyboard.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/ops_counts_cubit.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';
import 'package:sapbaq_admin/features/mosques/data/mosque_lookup_repository.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq_admin/features/rep/data/rep_repository.dart';
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

class _SapbaqAdminAppState extends State<SapbaqAdminApp>
    with WidgetsBindingObserver {
  late final AuthBloc _authBloc;
  late final SettingsCubit _settingsCubit;
  late final NotificationsBadgeCubit _badgeCubit;
  late final AdminRepository _adminRepository;
  late final OpsCountsCubit _opsCountsCubit;
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
    WidgetsBinding.instance.addObserver(this);
    _badgeCubit = NotificationsBadgeCubit(
      NotificationsRepository(widget.dio),
      // Foreground pushes carry `data.unread_count` for a live badge bump.
      pushData: widget.pushNotifications.onForegroundData,
    );
    _adminRepository = AdminRepository(widget.dio);
    _opsCountsCubit = OpsCountsCubit(_adminRepository);
    _router = createRouter(_authBloc);

    // Deep-link a tapped notification once the session is authenticated (§14):
    // a cold launch resolves auth asynchronously, so wait for it; runtime taps
    // fire the pendingNotification listener directly.
    _authStatusSub = _authBloc.stream.listen((state) {
      if (state.status == AuthStatus.authenticated) {
        _maybeNavigatePending();
        _badgeCubit.refresh();
        // Prime the operations badge: no shell lands on the hub anymore, so
        // without this the tab would show zero until first opened.
        _opsCountsCubit.load(state.user);
      } else if (state.status == AuthStatus.unauthenticated) {
        // Clear the bell/nav and OS icon badge on sign-out.
        _badgeCubit.setCount(0);
        _opsCountsCubit.reset();
      }
    });
    widget.pushNotifications.pendingNotification.addListener(
      _maybeNavigatePending,
    );
  }

  void _maybeNavigatePending() {
    final data = widget.pushNotifications.pendingNotification.value;
    if (data == null) return;
    final state = _authBloc.state;
    if (state.status != AuthStatus.authenticated) return;
    widget.pushNotifications.pendingNotification.value = null;
    // Resolve here, not in the push service: the same notification opens a
    // different screen for an imam than for a staff member, and the role is
    // only known now (a cold launch signs in after the tap arrives).
    final user = state.user;
    final route = resolveNotificationData(
      data,
      audience: audienceForRole(
        isMosqueRep: user?.isMosqueRep ?? false,
        isServiceHandler: user?.isServiceHandler ?? false,
      ),
    );
    if (route == null) return;
    // Defer a frame so the router has settled on the authenticated shell.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.pushNamed(
        route.name,
        pathParameters: route.pathParameters,
        queryParameters: route.queryParameters,
      );
    });
  }

  /// Pushes that arrive while the app is backgrounded never fire the
  /// foreground stream — re-read the standing counts on resume so the nav
  /// badges match what the tray has been showing.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final auth = _authBloc.state;
    if (auth.status != AuthStatus.authenticated) return;
    _badgeCubit.refresh();
    _opsCountsCubit.load(auth.user);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStatusSub?.cancel();
    widget.pushNotifications.pendingNotification.removeListener(
      _maybeNavigatePending,
    );
    _authBloc.close();
    _settingsCubit.close();
    _badgeCubit.close();
    _opsCountsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        // The push service, so feature code (e.g. the notifications inbox) can
        // subscribe to foreground pushes without new plumbing.
        RepositoryProvider<PushNotificationService>.value(
          value: widget.pushNotifications,
        ),
        RepositoryProvider<AdminRepository>.value(value: _adminRepository),
        RepositoryProvider<DriverRepository>(
          create: (_) => DriverRepository(widget.dio),
        ),
        RepositoryProvider<NotificationsRepository>(
          create: (_) => NotificationsRepository(widget.dio),
        ),
        // One mosque lookup for every picker in the app — staff and the
        // unauthenticated rep registration alike (both endpoints are public).
        RepositoryProvider<MosqueLookupRepository>(
          create: (_) => MosqueLookupRepository(widget.dio),
        ),
        RepositoryProvider<RepRepository>(
          create: (_) => RepRepository(widget.dio),
        ),
        // One instance app-wide so the permission is requested once and the
        // fix is shared by every queue that sorts nearest-first.
        RepositoryProvider<LocationService>(create: (_) => LocationService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _settingsCubit),
          BlocProvider.value(value: _badgeCubit),
          // App-wide: every shell's operations tab badge and the hub cards
          // read one set of counts, primed on sign-in by the auth listener
          // above and refreshed by the hub on every visit.
          BlocProvider.value(value: _opsCountsCubit),
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
                    child: DismissKeyboardOnTap(
                      child: child ?? const SizedBox.shrink(),
                    ),
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

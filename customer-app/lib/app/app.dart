import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_router.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/notifications/push_notification_service.dart';
import 'package:sapbaq/core/payments/payment_activity.dart';
import 'package:sapbaq/core/settings/settings_cubit.dart';
import 'package:sapbaq/core/settings/settings_service.dart';
import 'package:sapbaq/core/theme/app_theme.dart';
import 'package:sapbaq/core/widgets/dismiss_keyboard.dart';
import 'package:sapbaq/features/addresses/data/addresses_repository.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/banners/data/banners_repository.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/info/data/content_repository.dart';
import 'package:sapbaq/features/equipment/data/equipment_repository.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/favorites_cubit.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/features/products/data/products_repository.dart';
import 'package:sapbaq/features/showcase/data/showcase_repository.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';
import 'package:sapbaq/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq/features/support/presentation/bloc/support_unread_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class SapbaqApp extends StatefulWidget {
  final Dio dio;
  final AuthRepository authRepository;
  final SettingsService settingsService;
  final ValueNotifier<String> languageCode;
  final PushNotificationService pushNotifications;

  const SapbaqApp({
    super.key,
    required this.dio,
    required this.authRepository,
    required this.settingsService,
    required this.languageCode,
    required this.pushNotifications,
  });

  @override
  State<SapbaqApp> createState() => _SapbaqAppState();
}

class _SapbaqAppState extends State<SapbaqApp> {
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

    // Deep-link a tapped notification once the session is authenticated: a cold
    // launch resolves auth asynchronously, so wait for it; runtime taps fire the
    // pendingRoute listener directly.
    _authStatusSub = _authBloc.stream.listen((state) {
      if (state.status == AuthStatus.authenticated) _maybeNavigatePending();
    });
    widget.pushNotifications.pendingRoute.addListener(_maybeNavigatePending);
    // A payment in flight parks deep-links rather than dropping them; this
    // releases the queued one the moment the payment page closes.
    PaymentActivity.inFlight.addListener(_maybeNavigatePending);
  }

  void _maybeNavigatePending() {
    final route = widget.pushNotifications.pendingRoute.value;
    if (route == null) return;
    if (_authBloc.state.status != AuthStatus.authenticated) return;
    // Never navigate out from under a customer who is mid-payment. The route
    // stays queued and this runs again when the flag falls.
    if (PaymentActivity.inFlight.value) return;
    widget.pushNotifications.pendingRoute.value = null;
    // Defer a frame so the router has settled on the authenticated shell.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.pushNamed(
        route.name,
        pathParameters: route.pathParameters,
        queryParameters: route.queryParameters,
      );
    });
  }

  @override
  void dispose() {
    _authStatusSub?.cancel();
    widget.pushNotifications.pendingRoute.removeListener(_maybeNavigatePending);
    PaymentActivity.inFlight.removeListener(_maybeNavigatePending);
    _authBloc.close();
    _settingsCubit.close();
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
        RepositoryProvider<AddressesRepository>(
          create: (_) => AddressesRepository(widget.dio),
        ),
        RepositoryProvider<ProductsRepository>(
          create: (_) => ProductsRepository(widget.dio),
        ),
        RepositoryProvider<MosquesRepository>(
          create: (_) => MosquesRepository(widget.dio),
        ),
        RepositoryProvider<BannersRepository>(
          create: (_) => BannersRepository(widget.dio),
        ),
        RepositoryProvider<CartRepository>(
          create: (_) => CartRepository(widget.dio),
        ),
        RepositoryProvider<PaymentRepository>(
          create: (_) => PaymentRepository(widget.dio),
        ),
        RepositoryProvider<OrdersRepository>(
          create: (_) => OrdersRepository(widget.dio),
        ),
        RepositoryProvider<NotificationsRepository>(
          create: (_) => NotificationsRepository(widget.dio),
        ),
        RepositoryProvider<ContentRepository>(
          create: (_) => ContentRepository(widget.dio),
        ),
        RepositoryProvider<ShowcaseRepository>(
          create: (_) => ShowcaseRepository(widget.dio),
        ),
        RepositoryProvider<SupportRepository>(
          create: (_) => SupportRepository(widget.dio),
        ),
        RepositoryProvider<EquipmentRepository>(
          create: (_) => EquipmentRepository(widget.dio),
        ),
        RepositoryProvider<MarketplaceRepository>(
          create: (_) => MarketplaceRepository(widget.dio),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _settingsCubit),
          BlocProvider<CartCubit>(
            create: (context) => CartCubit(context.read<CartRepository>()),
          ),
          BlocProvider<FavoritesCubit>(
            create: (context) =>
                FavoritesCubit(context.read<MosquesRepository>()),
          ),
          BlocProvider<SupportUnreadCubit>(
            create: (context) =>
                SupportUnreadCubit(context.read<SupportRepository>()),
          ),
          BlocProvider<NotificationsBadgeCubit>(
            create: (context) => NotificationsBadgeCubit(
              context.read<NotificationsRepository>(),
            ),
          ),
        ],
        child: _PushForegroundListener(
          pushNotifications: widget.pushNotifications,
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settings) {
              return MaterialApp.router(
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: settings.themeMode,
                locale: settings.locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: _router,
                // Sensible status-bar icon brightness for screens without an
                // AppBar (Home, splash); AppBar screens still override this.
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

/// Keeps app-level state in step with the world outside the widget tree:
///
///  * a foreground push refreshes the support and bell badges, so nothing
///    derived from server state goes stale while the user is looking at it;
///  * returning from the background re-reads both counts — pushes that arrived
///    while backgrounded never fire the foreground stream;
///  * signing out clears them (and with them the OS app-icon badge), so a
///    logged-out device doesn't keep advertising the previous user's unread;
///  * a language switch re-applies the Android channel's localized name
///    (Android allows updating a channel's name/description in place).
class _PushForegroundListener extends StatefulWidget {
  final PushNotificationService pushNotifications;
  final Widget child;

  const _PushForegroundListener({
    required this.pushNotifications,
    required this.child,
  });

  @override
  State<_PushForegroundListener> createState() =>
      _PushForegroundListenerState();
}

class _PushForegroundListenerState extends State<_PushForegroundListener>
    with WidgetsBindingObserver {
  StreamSubscription<RemoteMessage>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = widget.pushNotifications.onForegroundMessage.listen((message) {
      if (!mounted) return;
      // Cheap and always correct: re-read the unread count from the server
      // rather than trying to infer it from the payload's type.
      context.read<SupportUnreadCubit>().refresh();
      // The push carries the post-arrival unread total (`data.unread_count`) —
      // use it directly for a live bell badge, falling back to a fetch.
      final raw = message.data['unread_count'];
      final unread = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      final badge = context.read<NotificationsBadgeCubit>();
      if (unread != null) {
        badge.setCount(unread);
      } else {
        badge.refresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    if (context.read<AuthBloc>().state.status != AuthStatus.authenticated) {
      return;
    }
    context.read<NotificationsBadgeCubit>().refresh();
    context.read<SupportUnreadCubit>().refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, SettingsState>(
          listenWhen: (a, b) => a.locale != b.locale,
          listener: (_, settings) => widget.pushNotifications
              .updateChannelLocalization(settings.locale),
        ),
        // Sign-out (to the login screen or down to guest): zero the badges so
        // the OS icon badge doesn't keep the previous user's count. The next
        // sign-in reloads them via the shell.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (a, b) =>
              a.status == AuthStatus.authenticated &&
              (b.status == AuthStatus.unauthenticated ||
                  b.status == AuthStatus.guest),
          listener: (context, _) {
            context.read<NotificationsBadgeCubit>().reset();
            context.read<SupportUnreadCubit>().reset();
          },
        ),
      ],
      child: widget.child,
    );
  }
}

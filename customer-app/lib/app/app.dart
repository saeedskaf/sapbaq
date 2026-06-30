import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_router.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/notifications/push_notification_service.dart';
import 'package:sapbaq/core/settings/settings_cubit.dart';
import 'package:sapbaq/core/settings/settings_service.dart';
import 'package:sapbaq/core/theme/app_theme.dart';
import 'package:sapbaq/features/addresses/data/addresses_repository.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/banners/data/banners_repository.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/gifts/data/gifts_repository.dart';
import 'package:sapbaq/features/info/data/content_repository.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/favorites_cubit.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/features/products/data/products_repository.dart';
import 'package:sapbaq/features/showcase/data/showcase_repository.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';
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
        RepositoryProvider<GiftsRepository>(
          create: (_) => GiftsRepository(widget.dio),
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _settingsCubit),
          BlocProvider<CartCubit>(
            create: (context) => CartCubit(
              context.read<CartRepository>(),
              context.read<GiftsRepository>(),
            ),
          ),
          BlocProvider<FavoritesCubit>(
            create: (context) =>
                FavoritesCubit(context.read<MosquesRepository>()),
          ),
          BlocProvider<SupportUnreadCubit>(
            create: (context) =>
                SupportUnreadCubit(context.read<SupportRepository>()),
          ),
        ],
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
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

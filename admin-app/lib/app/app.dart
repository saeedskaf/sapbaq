import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_router.dart';
import 'package:sapbaq_admin/core/constants/app_constants.dart';
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

  const SapbaqAdminApp({
    super.key,
    required this.dio,
    required this.authRepository,
  });

  @override
  State<SapbaqAdminApp> createState() => _SapbaqAdminAppState();
}

class _SapbaqAdminAppState extends State<SapbaqAdminApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(widget.authRepository)
      ..add(const AuthSubscriptionRequested());
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
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

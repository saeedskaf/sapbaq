import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';

/// Navigates off a **pushed** sign-in screen once auth resolves.
///
/// The router redirect handles screens reached with `go` (splash/onboarding),
/// but it cannot pop an imperatively-pushed route — e.g. login pushed over the
/// guest shell, or the OTP/passcode screens pushed on top of login. Wrapping
/// those screens in this listener moves the user forward explicitly when the
/// session status advances.
class AuthFlowListener extends StatelessWidget {
  final Widget child;
  const AuthFlowListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        switch (state.status) {
          case AuthStatus.authenticated:
          case AuthStatus.guest:
            context.goNamed(AppRoutes.homeName);
          case AuthStatus.completingProfile:
            context.goNamed(
              state.user?.phone == null
                  ? AppRoutes.verifyPhoneName
                  : AppRoutes.completeProfileName,
            );
          case AuthStatus.settingPasscode:
            context.goNamed(AppRoutes.setPasscodeName);
          case AuthStatus.locked:
            context.goNamed(AppRoutes.lockName);
          case AuthStatus.unauthenticated:
          case AuthStatus.unknown:
            break;
        }
      },
      child: child,
    );
  }
}

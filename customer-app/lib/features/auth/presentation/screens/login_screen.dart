import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/login_cubit.dart';
import 'package:sapbaq/features/auth/presentation/passkey_messages.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/features/auth/presentation/widgets/social_sign_in_button.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Passwordless entry point: continue with Google, Apple, or a phone OTP.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _phone = '';
  String? _phoneClientError;
  bool _passkeysSupported = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthRepository>().passkeysSupported().then((supported) {
      if (mounted) setState(() => _passkeysSupported = supported);
    });
  }

  void _requestOtp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    setState(
      () => _phoneClientError = _phone.isEmpty ? l10n.phoneRequired : null,
    );
    if (_phoneClientError != null) return;
    context.read<LoginCubit>().requestOtp(phone: _phone);
  }

  /// Where to land once the session resolves after sign-in.
  void _navigateForStatus(BuildContext context, AuthState state) {
    switch (state.status) {
      case AuthStatus.completingProfile:
        context.goNamed(
          state.user?.phone == null
              ? AppRoutes.verifyPhoneName
              : AppRoutes.completeProfileName,
        );
      case AuthStatus.guest:
      case AuthStatus.authenticated:
        context.goNamed(AppRoutes.homeName);
      case AuthStatus.unknown:
      case AuthStatus.unauthenticated:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return BlocProvider(
      create: (_) => LoginCubit(context.read<AuthRepository>()),
      child: BlocListener<AuthBloc, AuthState>(
        // After "browse as guest" or any successful sign-in, move off the login
        // screen. When it was pushed over the guest shell the router redirect
        // can't pop it on its own, so navigate explicitly.
        listenWhen: (a, b) =>
            a.status != b.status &&
            (b.status == AuthStatus.guest ||
                b.status == AuthStatus.authenticated ||
                b.status == AuthStatus.completingProfile),
        listener: _navigateForStatus,
        child: BlocConsumer<LoginCubit, LoginState>(
          listenWhen: (a, b) => a != b,
          listener: (context, state) {
            if (state.message != null) {
              ShowMessage.error(context, state.message!);
            }
            if (state.passkeyFailure != null) {
              ShowMessage.error(
                context,
                passkeyFailureMessage(l10n, state.passkeyFailure!),
              );
            }
            if (state.failed) {
              ShowMessage.error(context, l10n.signInError);
            }
            if (state.otpSent && state.phone != null) {
              context.pushNamed(
                AppRoutes.otpName,
                queryParameters: {'phone': state.phone!},
              );
            }
          },
          builder: (context, state) {
            return AuthScaffold(
              title: l10n.loginTitle,
              subtitle: l10n.loginSubtitle,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhoneFieldCustom(
                      label: l10n.phoneLabel,
                      onChanged: (p) => _phone = p.completeNumber,
                      errorText: _phoneClientError ?? state.phoneError,
                    ),
                    const SizedBox(height: 16),
                    ButtonCustom.primary(
                      text: l10n.sendCodeButton,
                      isLoading: state.busy == LoginAction.otp,
                      onPressed: state.isBusy
                          ? null
                          : () => _requestOtp(context),
                    ),
                    const SizedBox(height: 20),
                    _OrDivider(label: l10n.orSeparator),
                    const SizedBox(height: 20),
                    SocialSignInButton.google(
                      label: l10n.continueWithGoogle,
                      brightness: Theme.of(context).brightness,
                      isLoading: state.busy == LoginAction.google,
                      onPressed: state.isBusy
                          ? null
                          : () => context.read<LoginCubit>().signInWithGoogle(),
                    ),
                    if (isIOS) ...[
                      const SizedBox(height: 12),
                      SocialSignInButton.apple(
                        label: l10n.continueWithApple,
                        brightness: Theme.of(context).brightness,
                        isLoading: state.busy == LoginAction.apple,
                        onPressed: state.isBusy
                            ? null
                            : () =>
                                  context.read<LoginCubit>().signInWithApple(),
                      ),
                    ],
                    if (_passkeysSupported) ...[
                      const SizedBox(height: 12),
                      ButtonCustom.secondary(
                        text: l10n.passkeySignIn,
                        icon: const Icon(Icons.fingerprint_rounded, size: 20),
                        isLoading: state.busy == LoginAction.passkey,
                        onPressed: state.isBusy
                            ? null
                            : () => context
                                  .read<LoginCubit>()
                                  .signInWithPasskey(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () {
                            final auth = context.read<AuthBloc>();
                            // Already browsing as a guest (login opened over
                            // the guest shell): the status can't change, so
                            // the navigation listener would never fire — go
                            // straight back home instead.
                            if (auth.state.status == AuthStatus.guest) {
                              context.goNamed(AppRoutes.homeName);
                            } else {
                              auth.add(const AuthGuestRequested());
                            }
                          },
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: context.colors.textSecondary,
                    ),
                    label: TextCustom(
                      text: l10n.browseAsGuest,
                      color: context.colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A horizontal rule with a centered label (e.g. "or").
class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextCustom(
            text: label,
            color: context.colors.textHint,
            fontSize: 13,
          ),
        ),
        Expanded(child: Divider(color: context.colors.border, thickness: 1)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/phone_rules.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/login_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_flow_listener.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/features/auth/presentation/widgets/social_sign_in_button.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Entry screen (Sapbaq_AUTH_Flow §4): continue with a mobile number, Google,
/// or Apple — plus browse as guest. The number used before on this device is
/// pre-filled with a "Not me?" control. One field, two outcomes: the server's
/// number check decides passcode (sign-in) vs OTP (sign-up).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _phone = '';
  String? _phoneClientError;
  String? _remembered; // full number, e.g. +96512345678
  Key _phoneFieldKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    context.read<AuthRepository>().rememberedPhone().then((value) {
      if (!mounted || value == null || value.isEmpty) return;
      setState(() {
        _remembered = value;
        _phone = value;
        // Swap the key so IntlPhoneField rebuilds and picks up initialValue —
        // it only reads initialValue in its own initState, and this load
        // resolves after the first build.
        _phoneFieldKey = UniqueKey();
      });
    });
  }

  /// The national part of the remembered number, for the phone field's prefill.
  String? get _rememberedNational {
    final r = _remembered;
    if (r == null) return null;
    return r.startsWith('+965') ? r.substring(4) : r;
  }

  void _forgetNumber() {
    context.read<AuthRepository>().forgetRememberedPhone();
    setState(() {
      _remembered = null;
      _phone = '';
      _phoneClientError = null;
      _phoneFieldKey = UniqueKey(); // reset the phone field
    });
  }

  void _continue(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final issue = checkSupportedPhone(_phone);
    setState(() {
      _phoneClientError = switch (issue) {
        PhoneIssue.none => null,
        PhoneIssue.empty => l10n.phoneRequired,
        PhoneIssue.unsupportedCountry => l10n.phoneKuwaitOnly,
        PhoneIssue.length => l10n.phoneKuwaitOnly,
      };
    });
    if (_phoneClientError != null) return;
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().checkNumber(phone: _phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return BlocProvider(
      create: (_) => LoginCubit(context.read<AuthRepository>()),
      // Login can be pushed over the guest shell, so the router redirect can't
      // pop it — navigate explicitly when auth resolves (guest, sign-in,
      // onboarding). Covers "browse as guest" and a returning social sign-in.
      child: AuthFlowListener(
        child: BlocConsumer<LoginCubit, LoginState>(
          listenWhen: (a, b) => a != b,
          listener: (context, state) {
            if (state.message != null) {
              ShowMessage.error(context, state.message!);
            }
            if (state.failed) ShowMessage.error(context, l10n.signInError);
            if (state.nav == LoginNav.passcode && state.phone != null) {
              context.pushNamed(
                AppRoutes.passcodeLoginName,
                queryParameters: {'phone': state.phone!},
              );
            }
            if (state.nav == LoginNav.otp && state.phone != null) {
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
                      key: _phoneFieldKey,
                      label: l10n.phoneLabel,
                      initialValue: _rememberedNational,
                      onChanged: (p) => _phone = p.completeNumber,
                      errorText: _phoneClientError ?? state.phoneError,
                    ),
                    if (_remembered != null)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: state.isBusy ? null : _forgetNumber,
                          child: TextCustom(
                            text: l10n.notMe,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ButtonCustom.primary(
                      text: l10n.continueButton,
                      isLoading: state.busy == LoginAction.check,
                      onPressed: state.isBusy ? null : () => _continue(context),
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
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () {
                            final auth = context.read<AuthBloc>();
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

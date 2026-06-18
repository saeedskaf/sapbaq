import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/login_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String _phone = '';
  String? _phoneClientError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phoneClientError = _phone.isEmpty ? l10n.phoneRequired : null);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _phoneClientError != null) return;
    context.read<LoginCubit>().submit(
      phone: _phone,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return BlocProvider(
      create: (_) => LoginCubit(context.read<AuthRepository>()),
      child: BlocListener<AuthBloc, AuthState>(
        // After "browse as guest" OR a successful sign-in, land on home. When
        // the login screen is pushed over the guest shell, the router's
        // redirect can't pop it on its own (home is already active below), so
        // navigate explicitly here.
        listenWhen: (a, b) =>
            a.status != b.status &&
            (b.status == AuthStatus.guest ||
                b.status == AuthStatus.authenticated),
        listener: (context, _) => context.goNamed(AppRoutes.homeName),
        child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure && state.message != null) {
            ShowMessage.error(context, state.message!);
          }
        },
        builder: (context, state) {
          final loading = state.status == FormStatus.submitting;
          return AuthScaffold(
            title: l10n.loginTitle,
            subtitle: l10n.loginSubtitle,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhoneFieldCustom(
                      label: l10n.phoneLabel,
                      onChanged: (p) => _phone = p.completeNumber,
                      errorText: _phoneClientError ?? state.phoneError,
                    ),
                    const SizedBox(height: 18),
                    FormFieldCustom(
                      controller: _passwordController,
                      label: l10n.passwordLabel,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: validators.passwordValidator,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () =>
                            context.pushNamed(AppRoutes.forgotPasswordName),
                        child: TextCustom(
                          text: l10n.forgotPasswordLink,
                          color: context.colors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ButtonCustom.primary(
                      text: l10n.loginButton,
                      isLoading: loading,
                      onPressed: loading ? null : () => _submit(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextCustom(
                    text: l10n.noAccountQuestion,
                    color: context.colors.textSecondary,
                    fontSize: 14,
                  ),
                  TextButton(
                    onPressed: () => context.pushNamed(AppRoutes.signupName),
                    child: TextCustom(
                      text: l10n.createAccountLink,
                      color: context.colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthGuestRequested()),
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

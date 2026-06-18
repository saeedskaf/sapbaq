import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/form_status.dart';
import 'package:sapbaq_admin/core/utils/form_validators.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/login_cubit.dart';
import 'package:sapbaq_admin/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Staff login (ADMIN / DRIVER). On success the session becomes authenticated
/// and the router redirects to the matching role area. There is no self-signup
/// or guest mode — accounts are provisioned on the backend.
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
    setState(
      () => _phoneClientError = _phone.isEmpty ? l10n.phoneRequired : null,
    );
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
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure && state.message != null) {
            ShowMessage.error(context, state.message!);
          }
          // On success the AuthBloc flips to authenticated and the router
          // redirects to the role area — no explicit navigation needed here.
        },
        builder: (context, state) {
          final loading = state.status == FormStatus.submitting;
          return AuthScaffold(
            title: l10n.loginTitle,
            subtitle: l10n.loginStaffSubtitle,
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
                      onSubmitted: (_) => _submit(context),
                    ),
                    const SizedBox(height: 24),
                    ButtonCustom.primary(
                      text: l10n.loginButton,
                      isLoading: loading,
                      onPressed: loading ? null : () => _submit(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _phone = '';
  String? _phoneClientError;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phoneClientError = _phone.isEmpty ? l10n.phoneRequired : null);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _phoneClientError != null) return;
    context.read<SignupCubit>().submit(
      fullName: _nameController.text.trim(),
      phone: _phone,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return BlocProvider(
      create: (_) => SignupCubit(context.read<AuthRepository>()),
      child: BlocConsumer<SignupCubit, SignupState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure && state.message != null) {
            ShowMessage.error(context, state.message!);
          } else if (state.status == FormStatus.success) {
            // Account created, OTP sent — go verify it. In dev the backend
            // returns the code (no real SMS), so pass it along to show it.
            context.pushNamed(
              AppRoutes.otpName,
              queryParameters: {
                'phone': state.phone,
                if (state.devCode != null) 'devCode': state.devCode!,
              },
            );
          }
        },
        builder: (context, state) {
          final loading = state.status == FormStatus.submitting;
          return AuthScaffold(
            title: l10n.signupTitle,
            subtitle: l10n.signupSubtitle,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormFieldCustom(
                      controller: _nameController,
                      label: l10n.fullNameLabel,
                      textInputAction: TextInputAction.next,
                      validator: validators.fullNameValidator,
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 16),
                    ButtonCustom.primary(
                      text: l10n.signupButton,
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
                    text: l10n.haveAccountQuestion,
                    color: context.colors.textSecondary,
                    fontSize: 14,
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: TextCustom(
                      text: l10n.loginLink,
                      color: context.colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

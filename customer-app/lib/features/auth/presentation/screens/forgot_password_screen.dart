import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  String _phone = '';
  String? _phoneClientError;

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phoneClientError = _phone.isEmpty ? l10n.phoneRequired : null);
    if (_phoneClientError != null) return;
    context.read<ForgotPasswordCubit>().submit(phone: _phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => ForgotPasswordCubit(context.read<AuthRepository>()),
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure && state.message != null) {
            ShowMessage.error(context, state.message!);
          } else if (state.status == FormStatus.success) {
            context.pushNamed(
              AppRoutes.resetPasswordName,
              queryParameters: {'phone': state.phone},
            );
          }
        },
        builder: (context, state) {
          final loading = state.status == FormStatus.submitting;
          return AuthScaffold(
            title: l10n.forgotPasswordTitle,
            subtitle: l10n.forgotPasswordSubtitle,
            children: [
              PhoneFieldCustom(
                label: l10n.phoneLabel,
                onChanged: (p) => _phone = p.completeNumber,
                errorText: _phoneClientError,
              ),
              const SizedBox(height: 24),
              ButtonCustom.primary(
                text: l10n.sendCodeButton,
                isLoading: loading,
                onPressed: loading ? null : () => _submit(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

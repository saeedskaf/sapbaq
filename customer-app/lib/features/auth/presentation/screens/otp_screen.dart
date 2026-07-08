import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/otp_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Login-OTP code step. On a verified code the repository publishes the session
/// and this screen routes to the app (or the profile-completion flow when the
/// backend flags `needs_profile`).
class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<OtpCubit>().verify(
      phone: widget.phone,
      code: _codeController.text.trim(),
    );
  }

  void _navigateForStatus(BuildContext context, AuthState state) {
    switch (state.status) {
      case AuthStatus.completingProfile:
        context.goNamed(
          state.user?.phone == null
              ? AppRoutes.verifyPhoneName
              : AppRoutes.completeProfileName,
        );
      case AuthStatus.authenticated:
        context.goNamed(AppRoutes.homeName);
      case AuthStatus.guest:
      case AuthStatus.unknown:
      case AuthStatus.unauthenticated:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return BlocProvider(
      create: (_) => OtpCubit(context.read<AuthRepository>()),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (a, b) =>
            a.status != b.status &&
            (b.status == AuthStatus.authenticated ||
                b.status == AuthStatus.completingProfile),
        listener: _navigateForStatus,
        child: BlocConsumer<OtpCubit, OtpState>(
          listener: (context, state) {
            if (state.status == FormStatus.failure && state.message != null) {
              ShowMessage.error(context, state.message!);
            }
          },
          builder: (context, state) {
            final loading = state.status == FormStatus.submitting;
            return AuthScaffold(
              title: l10n.otpTitle,
              subtitle: l10n.otpSentTo(widget.phone),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormFieldCustom(
                        controller: _codeController,
                        label: l10n.otpLabel,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: validators.otpValidator,
                        onSubmitted: (_) => _submit(context),
                      ),
                      const SizedBox(height: 8),
                      ButtonCustom.primary(
                        text: l10n.verifyButton,
                        isLoading: loading,
                        onPressed: loading ? null : () => _submit(context),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () => context.read<OtpCubit>().resend(
                                  phone: widget.phone,
                                ),
                          child: TextCustom(
                            text: l10n.resendCode,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

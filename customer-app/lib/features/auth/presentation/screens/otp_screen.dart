import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/otp_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

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
    context.read<OtpCubit>().verify(
      phone: widget.phone,
      code: _codeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return BlocProvider(
      create: (_) => OtpCubit(context.read<AuthRepository>()),
      child: BlocConsumer<OtpCubit, OtpState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure && state.message != null) {
            ShowMessage.error(context, state.message!);
          } else if (state.status == FormStatus.success) {
            // Land on home explicitly — when this flow is pushed over the guest
            // shell, the auth redirect can't pop it on its own.
            context.goNamed(AppRoutes.homeName);
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: validators.otpValidator,
                    ),
                    const SizedBox(height: 8),
                    ButtonCustom.primary(
                      text: l10n.verifyButton,
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

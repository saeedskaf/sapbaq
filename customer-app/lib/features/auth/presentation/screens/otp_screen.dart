import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/utils/resend_cooldown.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/otp_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_flow_listener.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Verifies the OTP that establishes a phone (sign-up, or a legacy account that
/// still needs a passcode). On success the repository publishes the session and
/// the router advances to profile completion / passcode setup. The resend
/// button is disabled for 60s after each send (Sapbaq_AUTH_Flow §8).
class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final ResendCooldown _cooldown = ResendCooldown();

  @override
  void initState() {
    super.initState();
    // A code was just sent before we navigated here — start the cooldown.
    _cooldown.start();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldown.dispose();
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

  void _resend(BuildContext context) {
    context.read<OtpCubit>().resend(phone: widget.phone);
    _cooldown.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return BlocProvider(
      create: (_) => OtpCubit(context.read<AuthRepository>()),
      // Pushed over /login → the router redirect can't advance it; move forward
      // explicitly when the verified session resolves.
      child: AuthFlowListener(
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
              subtitle: l10n.otpSentTo(ltrIsolate(widget.phone)),
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
                        child: ValueListenableBuilder<int>(
                          valueListenable: _cooldown,
                          builder: (context, remaining, _) {
                            final active = remaining > 0;
                            return TextButton(
                              onPressed: (loading || active)
                                  ? null
                                  : () => _resend(context),
                              child: TextCustom(
                                text: active
                                    ? l10n.resendCodeIn(remaining)
                                    : l10n.resendCode,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? context.colors.textHint
                                    : context.colors.primary,
                              ),
                            );
                          },
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

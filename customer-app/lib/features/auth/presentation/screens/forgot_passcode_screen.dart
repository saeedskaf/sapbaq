import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/utils/passcode_rules.dart';
import 'package:sapbaq/core/utils/resend_cooldown.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/passcode_input.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/forgot_passcode_cubit.dart';
import 'package:sapbaq/features/auth/presentation/passcode_messages.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_flow_listener.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Passcode recovery (Sapbaq_AUTH_Flow §9): a recovery OTP plus a new 4-digit
/// passcode. A successful reset unlocks and signs in (session published).
class ForgotPasscodeScreen extends StatelessWidget {
  final String phone;
  const ForgotPasscodeScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ForgotPasscodeCubit(context.read<AuthRepository>(), phone: phone)
            ..sendCode(),
      child: _ForgotPasscodeView(phone: phone),
    );
  }
}

class _ForgotPasscodeView extends StatefulWidget {
  final String phone;
  const _ForgotPasscodeView({required this.phone});

  @override
  State<_ForgotPasscodeView> createState() => _ForgotPasscodeViewState();
}

class _ForgotPasscodeViewState extends State<_ForgotPasscodeView> {
  final _codeController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _confirmController = TextEditingController();
  final ResendCooldown _cooldown = ResendCooldown();
  String? _passcodeError;

  @override
  void initState() {
    super.initState();
    _cooldown.start();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passcodeController.dispose();
    _confirmController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    final passcode = _passcodeController.text;
    final confirm = _confirmController.text;

    if (code.length != 6) {
      ShowMessage.error(context, l10n.otpInvalid);
      return;
    }
    final issue = checkPasscode(passcode);
    if (issue != PasscodeIssue.none) {
      setState(() => _passcodeError = passcodeIssueMessage(l10n, issue));
      return;
    }
    if (passcode != confirm) {
      setState(() => _passcodeError = l10n.passcodeMismatch);
      return;
    }
    setState(() => _passcodeError = null);
    FocusScope.of(context).unfocus();
    context.read<ForgotPasscodeCubit>().reset(
      code: code,
      newPasscode: passcode,
    );
  }

  void _resend() {
    context.read<ForgotPasscodeCubit>().sendCode();
    _cooldown.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthFlowListener(
      child: BlocConsumer<ForgotPasscodeCubit, ForgotPasscodeState>(
        listener: (context, state) {
          if (state.message != null) ShowMessage.error(context, state.message!);
        },
        builder: (context, state) {
          return AuthScaffold(
            title: l10n.forgotPasscodeTitle,
            subtitle: l10n.forgotPasscodeSubtitle(ltrIsolate(widget.phone)),
            children: [
              FormFieldCustom(
                controller: _codeController,
                label: l10n.otpLabel,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: _cooldown,
                  builder: (context, remaining, _) {
                    final active = remaining > 0;
                    return TextButton(
                      onPressed: (state.busy || active) ? null : _resend,
                      child: TextCustom(
                        text: active
                            ? l10n.resendCodeIn(remaining)
                            : l10n.resendCode,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? context.colors.textHint
                            : context.colors.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _PasscodeLabel(text: l10n.newPasscodeLabel),
              const SizedBox(height: 10),
              PasscodeInput(
                controller: _passcodeController,
                autofocus: false,
                enabled: !state.busy,
                hasError: _passcodeError != null,
              ),
              const SizedBox(height: 16),
              _PasscodeLabel(text: l10n.confirmPasscodeLabel),
              const SizedBox(height: 10),
              PasscodeInput(
                controller: _confirmController,
                autofocus: false,
                enabled: !state.busy,
                hasError: _passcodeError != null,
              ),
              if (_passcodeError != null) ...[
                const SizedBox(height: 10),
                TextCustom(
                  text: _passcodeError!,
                  fontSize: 13,
                  color: ColorsCustom.error,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              ButtonCustom.primary(
                text: l10n.resetPasscodeButton,
                isLoading: state.busy,
                onPressed: state.busy ? null : _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PasscodeLabel extends StatelessWidget {
  final String text;
  const _PasscodeLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return TextCustom(
      text: text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: context.colors.textPrimary,
      textAlign: TextAlign.center,
    );
  }
}

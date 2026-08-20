import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/utils/passcode_rules.dart';
import 'package:sapbaq/core/utils/resend_cooldown.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/otp_input.dart';
import 'package:sapbaq/core/widgets/passcode_input.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/forgot_passcode_cubit.dart';
import 'package:sapbaq/features/auth/presentation/passcode_messages.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_flow_listener.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The three single-input stages of passcode recovery (Sapbaq_AUTH_Flow §9):
/// recovery code → new passcode → confirm. Each is its own screen so only one
/// field is ever shown at a time.
enum _Step { code, newPasscode, confirm }

/// Passcode recovery (Sapbaq_AUTH_Flow §9): a recovery OTP, then a new 4-digit
/// passcode entered and confirmed — one field per stage, each advancing
/// automatically. A successful reset unlocks and signs in (session published).
class ForgotPasscodeScreen extends StatelessWidget {
  final String phone;
  const ForgotPasscodeScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ForgotPasscodeCubit(context.read<AuthRepository>(), phone: phone),
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

  _Step _step = _Step.code;
  String _code = '';
  String _passcode = '';
  String? _error;

  String get _scope => 'forgot:${widget.phone}';

  @override
  void initState() {
    super.initState();
    // Resume an active cooldown (avoid a duplicate SMS on a quick reopen);
    // otherwise send the first recovery code.
    OtpCooldownStore.remaining(_scope).then((secs) {
      if (!mounted) return;
      if (secs > 0) {
        _cooldown.start(secs);
      } else {
        _send();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passcodeController.dispose();
    _confirmController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  /// Stage 1 → 2: the six-digit recovery code is captured (the server validates
  /// it together with the new passcode on reset).
  void _onCodeCompleted(String value) {
    FocusScope.of(context).unfocus();
    setState(() {
      _code = value;
      _error = null;
      _step = _Step.newPasscode;
    });
  }

  /// Stage 2 → 3: reject a weak passcode up front, otherwise move to confirm.
  void _onPasscodeCompleted(String value) {
    final l10n = AppLocalizations.of(context)!;
    final issue = checkPasscode(value);
    if (issue != PasscodeIssue.none) {
      setState(() => _error = passcodeIssueMessage(l10n, issue));
      _passcodeController.clear();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _passcode = value;
      _error = null;
      _step = _Step.confirm;
    });
  }

  /// Stage 3: must match the first entry, then submit the reset.
  void _onConfirmCompleted(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value != _passcode) {
      setState(() => _error = l10n.passcodeMismatch);
      _confirmController.clear();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    context.read<ForgotPasscodeCubit>().reset(
      code: _code,
      newPasscode: _passcode,
    );
  }

  void _back() {
    setState(() {
      _error = null;
      if (_step == _Step.confirm) {
        _confirmController.clear();
        _step = _Step.newPasscode;
      } else if (_step == _Step.newPasscode) {
        _passcodeController.clear();
        _step = _Step.code;
      }
    });
  }

  Future<void> _send() async {
    final secs = await context.read<ForgotPasscodeCubit>().sendCode();
    if (!mounted) return;
    await OtpCooldownStore.record(_scope, secs);
    _cooldown.start(secs);
  }

  void _resend() => _send();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthFlowListener(
      child: BlocConsumer<ForgotPasscodeCubit, ForgotPasscodeState>(
        listener: (context, state) {
          if (state.message != null) {
            // A reset failure most likely means a wrong/expired code — send the
            // user back to the first stage to start over.
            ShowMessage.error(context, state.message!);
            _codeController.clear();
            _passcodeController.clear();
            _confirmController.clear();
            setState(() {
              _code = '';
              _passcode = '';
              _error = null;
              _step = _Step.code;
            });
          }
        },
        builder: (context, state) {
          return AuthScaffold(
            title: l10n.forgotPasscodeTitle,
            subtitle: _subtitle(l10n),
            children: [
              const SizedBox(height: 8),
              _buildInput(state),
              if (_error != null) ...[
                const SizedBox(height: 14),
                TextCustom(
                  text: _error!,
                  fontSize: 13,
                  color: context.colors.danger,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              if (state.busy)
                Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(
                        context.colors.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _buildFooter(context, state, l10n),
            ],
          );
        },
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    switch (_step) {
      case _Step.code:
        return l10n.forgotPasscodeSubtitle(ltrIsolate(widget.phone));
      case _Step.newPasscode:
        return l10n.setPasscodeSubtitle;
      case _Step.confirm:
        return l10n.confirmPasscodeSubtitle;
    }
  }

  Widget _buildInput(ForgotPasscodeState state) {
    switch (_step) {
      case _Step.code:
        return OtpInput(
          key: const ValueKey('forgot-code'),
          controller: _codeController,
          enabled: !state.busy,
          hasError: _error != null,
          onCompleted: _onCodeCompleted,
        );
      case _Step.newPasscode:
        return PasscodeInput(
          key: const ValueKey('forgot-new'),
          controller: _passcodeController,
          enabled: !state.busy,
          hasError: _error != null,
          onCompleted: _onPasscodeCompleted,
        );
      case _Step.confirm:
        return PasscodeInput(
          key: const ValueKey('forgot-confirm'),
          controller: _confirmController,
          enabled: !state.busy,
          hasError: _error != null,
          onCompleted: _onConfirmCompleted,
        );
    }
  }

  Widget _buildFooter(
    BuildContext context,
    ForgotPasscodeState state,
    AppLocalizations l10n,
  ) {
    // First stage offers resend; later stages offer a step-back.
    if (_step == _Step.code) {
      return Center(
        child: ValueListenableBuilder<int>(
          valueListenable: _cooldown,
          builder: (context, remaining, _) {
            final active = remaining > 0;
            return TextButton(
              onPressed: (state.busy || active) ? null : _resend,
              child: TextCustom(
                text: active ? l10n.resendCodeIn(remaining) : l10n.resendCode,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active
                    ? context.colors.textHint
                    : context.colors.primary,
              ),
            );
          },
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: state.busy ? null : _back,
        child: TextCustom(
          text: l10n.back,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

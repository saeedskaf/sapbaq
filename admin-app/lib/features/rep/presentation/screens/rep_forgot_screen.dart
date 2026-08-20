import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/resend_cooldown.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/otp_input.dart';
import 'package:sapbaq_admin/core/widgets/passcode_input.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/auth/data/models/otp_send_meta.dart';
import 'package:sapbaq_admin/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq_admin/features/rep/presentation/widgets/resend_button.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The single-input stages of rep passcode recovery: phone → OTP → new passcode
/// → confirm. Each stage shows exactly one field and advances automatically.
enum _Step { phone, code, newPasscode, confirm }

/// Rep passcode recovery: phone → OTP → new passcode → confirm.
class RepForgotScreen extends StatefulWidget {
  const RepForgotScreen({super.key});

  @override
  State<RepForgotScreen> createState() => _RepForgotScreenState();
}

class _RepForgotScreenState extends State<RepForgotScreen> {
  final _codeController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.phone;
  String _phone = '';
  String? _phoneError;
  String? _error;
  bool _busy = false;
  final ResendCooldown _cooldown = ResendCooldown();

  String get _scope => 'rep_forgot:$_phone';

  @override
  void dispose() {
    _codeController.dispose();
    _passcodeController.dispose();
    _confirmController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phoneError = _phone.isEmpty ? l10n.phoneRequired : null);
    if (_phoneError != null) return;
    setState(() => _busy = true);
    try {
      final meta = await context.read<AuthRepository>().repRequestOtp(_phone);
      if (!mounted) return;
      setState(() => _step = _Step.code);
      await OtpCooldownStore.record(_scope, meta.resendAvailableIn);
      _cooldown.start(meta.resendAvailableIn);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Resend from the code stage (phone already captured).
  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      final meta = await context.read<AuthRepository>().repRequestOtp(_phone);
      if (!mounted) return;
      await OtpCooldownStore.record(_scope, meta.resendAvailableIn);
      _cooldown.start(meta.resendAvailableIn);
    } on ApiException catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, e.message);
      if (e.isThrottled) {
        final secs = e.retryAfter ?? kOtpDefaultResendSeconds;
        await OtpCooldownStore.record(_scope, secs);
        if (mounted) _cooldown.start(secs);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onCodeCompleted(String value) {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _step = _Step.newPasscode;
    });
  }

  void _onPasscodeCompleted(String value) {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _step = _Step.confirm;
    });
  }

  Future<void> _onConfirmCompleted(String value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value != _passcodeController.text) {
      setState(() => _error = l10n.repPasscodeMismatch);
      _confirmController.clear();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await context.read<AuthRepository>().repResetPasscode(
        phone: _phone,
        code: _codeController.text.trim(),
        passcode: _passcodeController.text,
      );
      if (!mounted) return;
      ShowMessage.success(context, l10n.repPasscodeResetDone);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      // Most likely a wrong/expired code — restart from the code stage.
      _codeController.clear();
      _passcodeController.clear();
      _confirmController.clear();
      setState(() {
        _step = _Step.code;
        _error = null;
      });
      ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    setState(() {
      _error = null;
      switch (_step) {
        case _Step.confirm:
          _confirmController.clear();
          _step = _Step.newPasscode;
        case _Step.newPasscode:
          _passcodeController.clear();
          _step = _Step.code;
        case _Step.code:
          _codeController.clear();
          _step = _Step.phone;
        case _Step.phone:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      title: l10n.repForgotPasscode,
      subtitle: _subtitle(l10n),
      children: [
        const SizedBox(height: 4),
        _buildInput(l10n),
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
        if (_busy && _step != _Step.phone)
          Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(context.colors.primary),
              ),
            ),
          ),
        if (_step != _Step.phone) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _back,
              child: TextCustom(
                text: l10n.back,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _subtitle(AppLocalizations l10n) {
    switch (_step) {
      case _Step.phone:
        return l10n.repForgotSubtitle;
      case _Step.code:
        return l10n.otpLabel;
      case _Step.newPasscode:
        return l10n.repPasscodeCreate;
      case _Step.confirm:
        return l10n.repPasscodeConfirm;
    }
  }

  Widget _buildInput(AppLocalizations l10n) {
    switch (_step) {
      case _Step.phone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhoneFieldCustom(
              label: l10n.phoneLabel,
              onChanged: (p) => _phone = p.completeNumber,
              errorText: _phoneError,
            ),
            const SizedBox(height: 24),
            ButtonCustom.primary(
              text: l10n.sendCodeButton,
              isLoading: _busy,
              onPressed: _busy ? null : _sendOtp,
            ),
          ],
        );
      case _Step.code:
        return Column(
          children: [
            OtpInput(
              key: const ValueKey('rep-forgot-code'),
              controller: _codeController,
              enabled: !_busy,
              hasError: _error != null,
              onCompleted: _onCodeCompleted,
            ),
            const SizedBox(height: 8),
            ResendButton(
              cooldown: _cooldown,
              enabled: !_busy,
              onResend: _resend,
            ),
          ],
        );
      case _Step.newPasscode:
        return PasscodeInput(
          key: const ValueKey('rep-forgot-new'),
          controller: _passcodeController,
          enabled: !_busy,
          hasError: _error != null,
          onCompleted: _onPasscodeCompleted,
        );
      case _Step.confirm:
        return PasscodeInput(
          key: const ValueKey('rep-forgot-confirm'),
          controller: _confirmController,
          enabled: !_busy,
          hasError: _error != null,
          onCompleted: _onConfirmCompleted,
        );
    }
  }
}

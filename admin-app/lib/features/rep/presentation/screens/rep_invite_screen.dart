import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';
import 'package:sapbaq_admin/features/rep/presentation/widgets/resend_button.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Single-input stages of invite-based registration: invite token → phone →
/// OTP → passcode → confirm. Each stage shows one field and advances on
/// completion.
enum _Step { token, phone, code, passcode, confirm }

/// Invite-based rep registration (Mosque Representative spec §3.B): the token
/// is pre-bound to a mosque, so there is no mosque selection — verify the
/// token, confirm the phone by OTP, set a passcode, and the account activates
/// immediately with a session.
class RepInviteScreen extends StatefulWidget {
  /// Deep-linked token (sapbaq admin invite link); null → manual entry.
  final String? token;

  const RepInviteScreen({super.key, this.token});

  @override
  State<RepInviteScreen> createState() => _RepInviteScreenState();
}

class _RepInviteScreenState extends State<RepInviteScreen> {
  final _tokenController = TextEditingController();
  final _codeController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.token;
  RepInviteInfo? _invite;
  String _phone = '';
  String? _phoneError;
  String? _error;
  bool _busy = false;
  final ResendCooldown _cooldown = ResendCooldown();

  String get _scope => 'rep_invite:$_phone';

  @override
  void initState() {
    super.initState();
    final token = widget.token;
    if (token != null && token.isNotEmpty) {
      _tokenController.text = token;
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _codeController.dispose();
    _passcodeController.dispose();
    _confirmController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final l10n = AppLocalizations.of(context)!;
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final invite = await context.read<AuthRepository>().repInviteInfo(token);
      if (mounted) {
        setState(() {
          _invite = invite;
          _step = _Step.phone;
        });
      }
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      _step = _Step.passcode;
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
      await context.read<AuthRepository>().repRegisterInvite(
        token: _tokenController.text.trim(),
        phone: _phone,
        code: _codeController.text.trim(),
        passcode: _passcodeController.text,
      );
      // ACTIVE + session → the router lands on the rep shell.
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
          _step = _Step.passcode;
        case _Step.passcode:
          _passcodeController.clear();
          _step = _Step.code;
        case _Step.code:
          _codeController.clear();
          _step = _Step.phone;
        case _Step.phone:
        case _Step.token:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      title: l10n.repInviteTitle,
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
        if (_busy && _step != _Step.token && _step != _Step.phone)
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
        if (_step == _Step.code ||
            _step == _Step.passcode ||
            _step == _Step.confirm) ...[
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
      case _Step.token:
        return l10n.repInviteSubtitle;
      case _Step.phone:
        return l10n.phoneLabel;
      case _Step.code:
        return l10n.otpLabel;
      case _Step.passcode:
        return l10n.repPasscodeCreate;
      case _Step.confirm:
        return l10n.repPasscodeConfirm;
    }
  }

  Widget _buildInput(AppLocalizations l10n) {
    switch (_step) {
      case _Step.token:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormFieldCustom(
              controller: _tokenController,
              label: l10n.repInviteToken,
            ),
            const SizedBox(height: 20),
            ButtonCustom.primary(
              text: l10n.repInviteCheck,
              isLoading: _busy,
              onPressed: _busy ? null : _lookup,
            ),
          ],
        );
      case _Step.phone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_invite != null) _MosqueBanner(name: _invite!.mosque.name),
            const SizedBox(height: 18),
            PhoneFieldCustom(
              label: l10n.phoneLabel,
              onChanged: (p) => _phone = p.completeNumber,
              errorText: _phoneError,
            ),
            const SizedBox(height: 20),
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
              key: const ValueKey('rep-invite-code'),
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
      case _Step.passcode:
        return PasscodeInput(
          key: const ValueKey('rep-invite-passcode'),
          controller: _passcodeController,
          enabled: !_busy,
          hasError: _error != null,
          onCompleted: _onPasscodeCompleted,
        );
      case _Step.confirm:
        return PasscodeInput(
          key: const ValueKey('rep-invite-confirm'),
          controller: _confirmController,
          enabled: !_busy,
          hasError: _error != null,
          onCompleted: _onConfirmCompleted,
        );
    }
  }
}

class _MosqueBanner extends StatelessWidget {
  final String name;
  const _MosqueBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.mosque_rounded, color: context.colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextCustom(
              text: name,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

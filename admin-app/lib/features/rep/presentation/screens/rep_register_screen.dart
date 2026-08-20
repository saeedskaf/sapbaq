import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
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
import 'package:sapbaq_admin/features/mosques/data/mosque_lookup_repository.dart';
import 'package:sapbaq_admin/features/mosques/presentation/widgets/mosque_browse_view.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The single-input stages of rep self-registration. Code/passcode stages show
/// exactly one field and advance on completion; name/mosque are ordinary form
/// steps with a Next button (name keeps first+last together by design).
enum _Step { phone, otp, name, mosque, passcode, confirm }

/// Mosque-representative self-registration wizard (Mosque Representative spec
/// §3.A): phone → OTP → name → governorate/area/mosque cascade (exact
/// selection, never free text) → 4-digit passcode → confirm → PENDING wait
/// screen.
class RepRegisterScreen extends StatefulWidget {
  const RepRegisterScreen({super.key});

  @override
  State<RepRegisterScreen> createState() => _RepRegisterScreenState();
}

class _RepRegisterScreenState extends State<RepRegisterScreen> {
  _Step _step = _Step.phone;

  // Identity.
  String _phone = '';
  String? _phoneError;
  final _codeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  /// The chosen mosque. Picked through the same governorate → area → mosque
  /// browser the rest of the app uses, so the walk is identical everywhere.
  PickableMosque? _mosque;

  // Passcode.
  final _passcodeController = TextEditingController();
  final _passcodeConfirmController = TextEditingController();
  String? _passcodeError;

  bool _busy = false;
  final ResendCooldown _cooldown = ResendCooldown();

  String get _scope => 'rep_register:$_phone';

  @override
  void dispose() {
    _codeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passcodeController.dispose();
    _passcodeConfirmController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  AuthRepository get _auth => context.read<AuthRepository>();

  Future<void> _requestOtp() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phoneError = _phone.isEmpty ? l10n.phoneRequired : null);
    if (_phoneError != null) return;
    setState(() => _busy = true);
    try {
      final meta = await _auth.repRequestOtp(_phone);
      if (!mounted) return;
      setState(() => _step = _Step.otp);
      await OtpCooldownStore.record(_scope, meta.resendAvailableIn);
      _cooldown.start(meta.resendAvailableIn);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Resend from the OTP stage (phone already captured).
  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      final meta = await _auth.repRequestOtp(_phone);
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
    setState(() => _step = _Step.name);
  }

  void _toMosqueStep() {
    final l10n = AppLocalizations.of(context)!;
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ShowMessage.error(context, l10n.repFillAllFields);
      return;
    }
    setState(() => _step = _Step.mosque);
  }

  void _onPasscodeCompleted(String value) {
    FocusScope.of(context).unfocus();
    setState(() {
      _passcodeError = null;
      _step = _Step.confirm;
    });
  }

  void _onConfirmCompleted(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value != _passcodeController.text) {
      setState(() {
        _passcodeError = l10n.repPasscodeMismatch;
        _step = _Step.passcode;
      });
      _passcodeController.clear();
      _passcodeConfirmController.clear();
      return;
    }
    _submit();
  }

  void _back() {
    setState(() {
      _passcodeError = null;
      switch (_step) {
        case _Step.confirm:
          _passcodeConfirmController.clear();
          _step = _Step.passcode;
        case _Step.passcode:
          _passcodeController.clear();
          _step = _Step.mosque;
        case _Step.mosque:
          _step = _Step.name;
        case _Step.name:
          _step = _Step.otp;
        case _Step.otp:
          _codeController.clear();
          _step = _Step.phone;
        case _Step.phone:
          break;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await _auth.repRegister(
        phone: _phone,
        code: _codeController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        mosqueId: _mosque!.id,
        passcode: _passcodeController.text,
      );
      if (mounted) context.goNamed(AppRoutes.repPendingName);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Most likely a wrong/expired code — restart from the code stage.
      _codeController.clear();
      _passcodeController.clear();
      _passcodeConfirmController.clear();
      setState(() {
        _step = _Step.otp;
        _passcodeError = null;
      });
      ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      title: l10n.repRegisterTitle,
      subtitle: _subtitle(l10n),
      children: [
        _StepDots(current: _step.index, total: _Step.values.length),
        const SizedBox(height: 20),
        ...switch (_step) {
          _Step.phone => _phoneStep(l10n),
          _Step.otp => _otpStep(l10n),
          _Step.name => _nameStep(l10n),
          _Step.mosque => _mosqueStep(l10n),
          _Step.passcode => _passcodeStep(l10n),
          _Step.confirm => _confirmStep(l10n),
        },
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
        return l10n.repRegisterPhoneStep;
      case _Step.otp:
        return l10n.otpLabel;
      case _Step.name:
        return l10n.repRegisterIdentityStep;
      case _Step.mosque:
        return l10n.repRegisterMosqueStep;
      case _Step.passcode:
        return l10n.repPasscodeCreate;
      case _Step.confirm:
        return l10n.repPasscodeConfirm;
    }
  }

  List<Widget> _phoneStep(AppLocalizations l10n) => [
    PhoneFieldCustom(
      label: l10n.phoneLabel,
      onChanged: (p) => _phone = p.completeNumber,
      errorText: _phoneError,
    ),
    const SizedBox(height: 24),
    ButtonCustom.primary(
      text: l10n.sendCodeButton,
      isLoading: _busy,
      onPressed: _busy ? null : _requestOtp,
    ),
  ];

  List<Widget> _otpStep(AppLocalizations l10n) => [
    OtpInput(
      key: const ValueKey('rep-register-code'),
      controller: _codeController,
      enabled: !_busy,
      onCompleted: _onCodeCompleted,
    ),
    const SizedBox(height: 8),
    ResendButton(cooldown: _cooldown, enabled: !_busy, onResend: _resend),
  ];

  List<Widget> _nameStep(AppLocalizations l10n) => [
    FormFieldCustom(controller: _firstNameController, label: l10n.repFirstName),
    const SizedBox(height: 14),
    FormFieldCustom(controller: _lastNameController, label: l10n.repLastName),
    const SizedBox(height: 24),
    ButtonCustom.primary(
      text: l10n.nextButton,
      isLoading: _busy,
      onPressed: _busy ? null : _toMosqueStep,
    ),
  ];

  List<Widget> _mosqueStep(AppLocalizations l10n) => [
    // The picker is the step: search plus the governorate → area drill-down,
    // exactly as staff pick a mosque. Bounded height because the wizard itself
    // scrolls.
    SizedBox(
      height: 420,
      child: MosqueBrowseView(
        bottomPadding: 8,
        onMosqueTap: (mosque) => setState(() => _mosque = mosque),
        trailingBuilder: (mosque) => Icon(
          mosque.id == _mosque?.id
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: mosque.id == _mosque?.id
              ? context.colors.primary
              : context.colors.textHint,
        ),
      ),
    ),
    const SizedBox(height: 16),
    ButtonCustom.primary(
      text: l10n.nextButton,
      onPressed: _mosque == null
          ? null
          : () => setState(() => _step = _Step.passcode),
    ),
  ];

  List<Widget> _passcodeStep(AppLocalizations l10n) => [
    const SizedBox(height: 4),
    PasscodeInput(
      key: const ValueKey('rep-register-passcode'),
      controller: _passcodeController,
      enabled: !_busy,
      hasError: _passcodeError != null,
      onCompleted: _onPasscodeCompleted,
    ),
    if (_passcodeError != null) ...[
      const SizedBox(height: 14),
      TextCustom(
        text: _passcodeError!,
        fontSize: 13,
        color: context.colors.danger,
        textAlign: TextAlign.center,
      ),
    ],
  ];

  List<Widget> _confirmStep(AppLocalizations l10n) => [
    const SizedBox(height: 4),
    PasscodeInput(
      key: const ValueKey('rep-register-confirm'),
      controller: _passcodeConfirmController,
      enabled: !_busy,
      onCompleted: _onConfirmCompleted,
    ),
    const SizedBox(height: 20),
    if (_busy)
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
  ];
}

class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return Container(
          width: i == current ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? context.colors.primary : context.colors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

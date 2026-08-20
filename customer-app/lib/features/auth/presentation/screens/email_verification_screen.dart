import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/utils/resend_cooldown.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/otp_input.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/email_verification_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Verify the account email — or move it to a different address. Two steps in
/// one screen: type the address, then confirm the code that lands in the inbox.
///
/// This is the only path that produces a *verified* address, and a verified
/// address is what lets a Google/Apple sign-in resolve to this account — which
/// is why it is proven by a mailed code rather than typed into the profile.
class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmailVerificationCubit(context.read<AuthRepository>()),
      child: const _EmailVerificationView(),
    );
  }
}

class _EmailVerificationView extends StatefulWidget {
  const _EmailVerificationView();

  @override
  State<_EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<_EmailVerificationView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final ResendCooldown _cooldown = ResendCooldown();

  /// True when the account already has a verified address — this run replaces
  /// it, so the old inbox gets a heads-up (and the copy says so).
  bool _isChange = false;

  /// The send cooldown is enforced per **account**, not per address: retyping
  /// the field must not revive the button. Keyed by user id for that reason.
  late final String _scope;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _isChange = user?.emailVerified ?? false;
    // Prefill the address on file: verifying it needs no retyping, and changing
    // it starts from something to edit.
    _emailController.text = user?.email ?? '';
    _scope = 'email:${user?.id ?? 0}';
    // Resume a cooldown still running from an earlier visit (it survives
    // leaving the screen and app restarts).
    OtpCooldownStore.remaining(_scope).then((secs) {
      if (mounted && secs > 0) _cooldown.start(secs);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    _apply(
      await context.read<EmailVerificationCubit>().requestCode(
        email: _emailController.text.trim(),
      ),
    );
  }

  Future<void> _resend(BuildContext context) async {
    _apply(await context.read<EmailVerificationCubit>().resend());
  }

  /// Land a send attempt on the screen's own state.
  ///
  /// The countdown starts *before* the write that persists it: touching the
  /// notifier after an `await` risks a screen the user has already left, and a
  /// disposed [ResendCooldown] would take a stray one-second timer with it.
  void _apply(EmailSendOutcome outcome) {
    if (!mounted) return;
    // A fresh code kills the previous one — never leave its digits on screen
    // looking like something that was entered against the live code.
    if (outcome.sent) _codeController.clear();
    if (outcome.cooldown <= 0) return;
    _cooldown.start(outcome.cooldown);
    OtpCooldownStore.record(_scope, outcome.cooldown);
  }

  void _verify(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<EmailVerificationCubit>().verify(
      code: _codeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: TextCustom(
          text: _isChange ? l10n.changeEmailTitle : l10n.verifyEmailTitle,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          // Verified → the response already updated the cached user, so just
          // re-read it into the app state, then hand the news to the profile.
          BlocListener<EmailVerificationCubit, EmailVerificationState>(
            listenWhen: (a, b) => !a.verified && b.verified,
            listener: (context, _) {
              context.read<AuthBloc>().add(const AuthUserRefreshed());
              ShowMessage.success(context, l10n.emailVerifiedSuccess);
              context.pop();
            },
          ),
          BlocListener<EmailVerificationCubit, EmailVerificationState>(
            listenWhen: (a, b) => b.message != null && a.message != b.message,
            listener: (context, state) {
              ShowMessage.error(context, state.message!);
              // A dead code is never worth retyping over — start clean.
              _codeController.clear();
            },
          ),
        ],
        child: BlocBuilder<EmailVerificationCubit, EmailVerificationState>(
          builder: (context, state) {
            final onCodeStep = state.step == EmailStep.enterCode;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                TextCustom(
                  text: onCodeStep
                      ? l10n.emailCodeSentTo(ltrIsolate(state.email ?? ''))
                      : l10n.verifyEmailSubtitle,
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(height: 20),
                if (!onCodeStep)
                  _EmailStep(
                    formKey: _formKey,
                    controller: _emailController,
                    errorText: state.emailError,
                    busy: state.busy,
                    cooldown: _cooldown,
                    validator: validators.combineValidators([
                      validators.requiredValidator,
                      validators.emailValidator,
                    ]),
                    onSend: () => _send(context),
                  )
                else
                  _CodeStep(
                    controller: _codeController,
                    busy: state.busy,
                    hasError: state.message != null,
                    cooldown: _cooldown,
                    showOldAddressNotice: _isChange,
                    onCompleted: () => _verify(context),
                    onResend: () => _resend(context),
                    onEditEmail: () =>
                        context.read<EmailVerificationCubit>().editEmail(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Step one: the address. The send button doubles as the cooldown readout —
/// the wait belongs to the account, so it is already ticking here when the user
/// arrives from an earlier send.
class _EmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String? errorText;
  final bool busy;
  final ResendCooldown cooldown;
  final FormFieldValidator<String> validator;
  final VoidCallback onSend;

  const _EmailStep({
    required this.formKey,
    required this.controller,
    required this.errorText,
    required this.busy,
    required this.cooldown,
    required this.validator,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormFieldCustom(
            controller: controller,
            label: l10n.emailLabel,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !busy,
            // The server's rejection rides alongside the client validator, not
            // through it: folding it in would block the next submit, since
            // validation runs before the request that would clear it.
            errorText: errorText,
            validator: validator,
            onSubmitted: (_) => onSend(),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<int>(
            valueListenable: cooldown,
            builder: (context, remaining, _) {
              final waiting = remaining > 0;
              return ButtonCustom.primary(
                text: waiting
                    ? l10n.resendCodeIn(remaining)
                    : l10n.sendCodeButton,
                isLoading: busy,
                onPressed: (busy || waiting) ? null : onSend,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Step two: the six digits. Auto-submits when complete, exactly like the SMS
/// code — same envelope, same error codes, same resend backoff.
class _CodeStep extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final bool hasError;
  final ResendCooldown cooldown;
  final bool showOldAddressNotice;
  final VoidCallback onCompleted;
  final VoidCallback onResend;
  final VoidCallback onEditEmail;

  const _CodeStep({
    required this.controller,
    required this.busy,
    required this.hasError,
    required this.cooldown,
    required this.showOldAddressNotice,
    required this.onCompleted,
    required this.onResend,
    required this.onEditEmail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        OtpInput(
          controller: controller,
          enabled: !busy,
          hasError: hasError,
          onCompleted: (_) => onCompleted(),
        ),
        const SizedBox(height: 24),
        if (busy)
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
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: cooldown,
          builder: (context, remaining, _) {
            final waiting = remaining > 0;
            return TextButton(
              onPressed: (busy || waiting) ? null : onResend,
              child: TextCustom(
                text: waiting ? l10n.resendCodeIn(remaining) : l10n.resendCode,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: waiting
                    ? context.colors.textHint
                    : context.colors.primary,
              ),
            );
          },
        ),
        TextButton(
          onPressed: busy ? null : onEditEmail,
          child: TextCustom(
            text: l10n.changeEmailAddress,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Only meaningful when there *is* a previous address — saying it to
        // someone verifying their first one would puzzle them.
        if (showOldAddressNotice) ...[
          const SizedBox(height: 12),
          TextCustom(
            text: l10n.emailOldAddressNotice,
            fontSize: 12,
            color: context.colors.textHint,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

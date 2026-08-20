import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/utils/resend_cooldown.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/otp_input.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/otp_send_meta.dart';
import 'package:sapbaq/features/auth/presentation/bloc/otp_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_flow_listener.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Verifies the OTP that establishes a phone (sign-up, or a legacy account that
/// still needs a passcode). The six-digit code auto-submits when complete; on
/// success the repository publishes the session and the router advances to
/// profile completion / passcode setup. The resend button is disabled for 60s
/// after each send (Sapbaq_AUTH_Flow §8).
class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  final ResendCooldown _cooldown = ResendCooldown();

  String get _scope => 'otp:${widget.phone}';

  @override
  void initState() {
    super.initState();
    // Resume any cooldown still running for this number (survives leaving and
    // returning, and app restarts); otherwise a code was just sent before we
    // navigated here, so start the server's default first wait.
    OtpCooldownStore.remaining(_scope).then((secs) {
      if (!mounted) return;
      if (secs > 0) {
        _cooldown.start(secs);
      } else {
        _cooldown.start(kOtpDefaultResendSeconds);
        OtpCooldownStore.record(_scope, kOtpDefaultResendSeconds);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<OtpCubit>().verify(
      phone: widget.phone,
      code: _codeController.text.trim(),
    );
  }

  Future<void> _resend(BuildContext context) async {
    final secs = await context.read<OtpCubit>().resend(phone: widget.phone);
    if (!mounted) return;
    await OtpCooldownStore.record(_scope, secs);
    _cooldown.start(secs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => OtpCubit(context.read<AuthRepository>()),
      // Pushed over /login → the router redirect can't advance it; move forward
      // explicitly when the verified session resolves.
      child: AuthFlowListener(
        child: BlocConsumer<OtpCubit, OtpState>(
          listener: (context, state) {
            if (state.status == FormStatus.failure && state.message != null) {
              ShowMessage.error(context, state.message!);
              // Clear so the user can re-enter the six digits cleanly.
              _codeController.clear();
            }
          },
          builder: (context, state) {
            final loading = state.status == FormStatus.submitting;
            final hasError = state.status == FormStatus.failure;
            return AuthScaffold(
              title: l10n.otpTitle,
              subtitle: l10n.otpSentTo(ltrIsolate(widget.phone)),
              children: [
                const SizedBox(height: 8),
                OtpInput(
                  controller: _codeController,
                  enabled: !loading,
                  hasError: hasError,
                  onCompleted: (_) => _submit(context),
                ),
                const SizedBox(height: 24),
                if (loading)
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
            );
          },
        ),
      ),
    );
  }
}

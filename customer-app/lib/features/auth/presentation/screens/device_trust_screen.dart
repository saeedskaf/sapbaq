import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/utils/resend_cooldown.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/device_trust_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_flow_listener.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// New/unrecognized device (Sapbaq_AUTH_Flow §7): a one-time OTP establishes
/// device trust, then the carried passcode is retried automatically so the sign
/// -in completes. On success the repository publishes the session.
class DeviceTrustScreen extends StatelessWidget {
  final String phone;
  final String passcode;
  const DeviceTrustScreen({
    super.key,
    required this.phone,
    required this.passcode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeviceTrustCubit(
        context.read<AuthRepository>(),
        phone: phone,
        passcode: passcode,
      )..sendCode(),
      child: _DeviceTrustView(phone: phone),
    );
  }
}

class _DeviceTrustView extends StatefulWidget {
  final String phone;
  const _DeviceTrustView({required this.phone});

  @override
  State<_DeviceTrustView> createState() => _DeviceTrustViewState();
}

class _DeviceTrustViewState extends State<_DeviceTrustView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final ResendCooldown _cooldown = ResendCooldown();

  @override
  void initState() {
    super.initState();
    _cooldown.start();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  void _verify() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<DeviceTrustCubit>().verify(code: _codeController.text.trim());
  }

  void _resend() {
    context.read<DeviceTrustCubit>().sendCode();
    _cooldown.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return AuthFlowListener(
      child: BlocConsumer<DeviceTrustCubit, DeviceTrustState>(
        listener: (context, state) {
          if (state.message != null) ShowMessage.error(context, state.message!);
        },
        builder: (context, state) {
          return AuthScaffold(
            title: l10n.deviceTrustTitle,
            subtitle: l10n.deviceTrustSubtitle(ltrIsolate(widget.phone)),
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
                      onSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 8),
                    ButtonCustom.primary(
                      text: l10n.verifyButton,
                      isLoading: state.busy,
                      onPressed: state.busy ? null : _verify,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/auth/presentation/bloc/phone_verification_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// First-use phone verification for a social sign-in that has no phone yet.
/// Two steps: enter a number → confirm the SMS code. On success the cached user
/// gains a verified phone and the router advances to profile completion.
class PhoneVerificationScreen extends StatelessWidget {
  const PhoneVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhoneVerificationCubit(context.read<AuthRepository>()),
      child: const _PhoneVerificationView(),
    );
  }
}

class _PhoneVerificationView extends StatefulWidget {
  const _PhoneVerificationView();

  @override
  State<_PhoneVerificationView> createState() => _PhoneVerificationViewState();
}

class _PhoneVerificationViewState extends State<_PhoneVerificationView> {
  final _codeController = TextEditingController();
  String _phone = '';
  String? _phoneClientError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _requestCode(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    setState(
      () => _phoneClientError = _phone.isEmpty ? l10n.phoneRequired : null,
    );
    if (_phoneClientError != null) return;
    FocusScope.of(context).unfocus();
    context.read<PhoneVerificationCubit>().requestCode(phone: _phone);
  }

  void _verify(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ShowMessage.error(context, l10n.otpInvalid);
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<PhoneVerificationCubit>().verify(code: code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return MultiBlocListener(
      listeners: [
        // Verified → refresh the cached user so the router (which gates on
        // user.phone) advances this onboarding to profile completion.
        BlocListener<PhoneVerificationCubit, PhoneVerificationState>(
          listenWhen: (a, b) => !a.verified && b.verified,
          listener: (context, _) =>
              context.read<AuthBloc>().add(const AuthUserRefreshed()),
        ),
        BlocListener<PhoneVerificationCubit, PhoneVerificationState>(
          listenWhen: (a, b) => b.message != null && a.message != b.message,
          listener: (context, state) =>
              ShowMessage.error(context, state.message!),
        ),
      ],
      child: BlocBuilder<PhoneVerificationCubit, PhoneVerificationState>(
        builder: (context, state) {
          final onCodeStep = state.step == PhoneStep.enterCode;
          return AuthScaffold(
            title: l10n.verifyPhoneTitle,
            subtitle: onCodeStep
                ? l10n.otpSentTo(state.phone ?? _phone)
                : l10n.verifyPhoneSubtitle,
            children: [
              if (!onCodeStep) ...[
                PhoneFieldCustom(
                  label: l10n.phoneLabel,
                  onChanged: (p) => _phone = p.completeNumber,
                  errorText: _phoneClientError ?? state.phoneError,
                ),
                const SizedBox(height: 16),
                ButtonCustom.primary(
                  text: l10n.sendCodeButton,
                  isLoading: state.busy,
                  onPressed: state.busy ? null : () => _requestCode(context),
                ),
              ] else ...[
                FormFieldCustom(
                  controller: _codeController,
                  label: l10n.otpLabel,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: validators.otpValidator,
                  onSubmitted: (_) => _verify(context),
                ),
                const SizedBox(height: 8),
                ButtonCustom.primary(
                  text: l10n.verifyButton,
                  isLoading: state.busy,
                  onPressed: state.busy ? null : () => _verify(context),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: state.busy
                        ? null
                        : () =>
                              context.read<PhoneVerificationCubit>().editPhone(),
                    child: TextCustom(
                      text: l10n.changeNumber,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthLogoutRequested()),
                  child: TextCustom(text: l10n.useDifferentAccount, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

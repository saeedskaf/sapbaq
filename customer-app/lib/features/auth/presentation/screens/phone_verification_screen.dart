import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/bidi.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/otp_input.dart';
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
  String _phone = ''; // full E.164 number
  String _phoneNational = ''; // national part only, used for the empty-guard
  String? _phoneClientError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _requestCode(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Country availability is enforced by the backend; the client only guards
    // against an empty submission and surfaces the server's rejection.
    setState(() {
      _phoneClientError = _phoneNational.trim().isEmpty
          ? l10n.phoneRequired
          : null;
    });
    if (_phoneClientError != null) return;
    FocusScope.of(context).unfocus();
    context.read<PhoneVerificationCubit>().requestCode(phone: _phone);
  }

  void _verify(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<PhoneVerificationCubit>().verify(
      code: _codeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          listener: (context, state) {
            ShowMessage.error(context, state.message!);
            // Clear the code so it can be re-entered cleanly.
            _codeController.clear();
          },
        ),
      ],
      child: BlocBuilder<PhoneVerificationCubit, PhoneVerificationState>(
        builder: (context, state) {
          final onCodeStep = state.step == PhoneStep.enterCode;
          return AuthScaffold(
            title: l10n.verifyPhoneTitle,
            subtitle: onCodeStep
                ? l10n.otpSentTo(ltrIsolate(state.phone ?? _phone))
                : l10n.verifyPhoneSubtitle,
            children: [
              if (!onCodeStep) ...[
                PhoneFieldCustom(
                  label: l10n.phoneLabel,
                  onChanged: (p) {
                    _phone = p.completeNumber;
                    _phoneNational = p.number;
                  },
                  errorText: _phoneClientError ?? state.phoneError,
                ),
                const SizedBox(height: 16),
                ButtonCustom.primary(
                  text: l10n.sendCodeButton,
                  isLoading: state.busy,
                  onPressed: state.busy ? null : () => _requestCode(context),
                ),
              ] else ...[
                const SizedBox(height: 8),
                OtpInput(
                  controller: _codeController,
                  enabled: !state.busy,
                  hasError: state.message != null,
                  onCompleted: (_) => _verify(context),
                ),
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
                Center(
                  child: TextButton(
                    onPressed: state.busy
                        ? null
                        : () => context
                              .read<PhoneVerificationCubit>()
                              .editPhone(),
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
                  child: TextCustom(
                    text: l10n.useDifferentAccount,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

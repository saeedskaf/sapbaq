import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/presentation/bloc/otp_cubit.dart';
import 'package:sapbaq/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  /// Dev-only OTP from the signup response (no real SMS in dev). When present,
  /// it's shown and pre-filled so testers can complete signup. Null in prod.
  final String? devCode;

  const OtpScreen({super.key, required this.phone, this.devCode});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController = TextEditingController(
    text: widget.devCode ?? '',
  );

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<OtpCubit>().verify(
      phone: widget.phone,
      code: _codeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);

    return BlocProvider(
      create: (_) => OtpCubit(context.read<AuthRepository>()),
      child: BlocConsumer<OtpCubit, OtpState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure && state.message != null) {
            ShowMessage.error(context, state.message!);
          } else if (state.status == FormStatus.success) {
            // Land on home explicitly — when this flow is pushed over the guest
            // shell, the auth redirect can't pop it on its own.
            context.goNamed(AppRoutes.homeName);
          }
        },
        builder: (context, state) {
          final loading = state.status == FormStatus.submitting;
          return AuthScaffold(
            title: l10n.otpTitle,
            subtitle: l10n.otpSentTo(widget.phone),
            children: [
              if (widget.devCode != null) ...[
                _DevCodeBanner(
                  code: widget.devCode!,
                  onTap: () => _codeController.text = widget.devCode!,
                ),
                const SizedBox(height: 16),
              ],
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
                    ),
                    const SizedBox(height: 8),
                    ButtonCustom.primary(
                      text: l10n.verifyButton,
                      isLoading: loading,
                      onPressed: loading ? null : () => _submit(context),
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

/// Dev-only banner showing the OTP returned by the backend (no real SMS in
/// dev). Tapping it re-fills the code field. Never shown in production (the
/// backend omits `dev_code`).
class _DevCodeBanner extends StatelessWidget {
  final String code;
  final VoidCallback onTap;
  const _DevCodeBanner({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.primaryTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: context.colors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    text: l10n.devOtpNotice,
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(height: 2),
                  TextCustom(
                    text: code,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.colors.primary,
                    letterSpacing: 6,
                  ),
                  const SizedBox(height: 4),
                  TextCustom(
                    text: l10n.devOtpTapToFill,
                    fontSize: 11,
                    color: context.colors.textHint,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

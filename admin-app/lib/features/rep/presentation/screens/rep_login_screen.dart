import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Mosque-representative daily login — step one: the phone number. Continuing
/// carries the phone to [RepPasscodeScreen] where the passcode is entered.
/// Also links to self-registration and invite registration.
class RepLoginScreen extends StatefulWidget {
  const RepLoginScreen({super.key});

  @override
  State<RepLoginScreen> createState() => _RepLoginScreenState();
}

class _RepLoginScreenState extends State<RepLoginScreen> {
  String _phone = '';
  String? _phoneError;

  void _continue() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phoneError = _phone.isEmpty ? l10n.phoneRequired : null);
    if (_phoneError != null) return;
    context.pushNamed(AppRoutes.repPasscodeName, extra: _phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      title: l10n.repLoginTitle,
      subtitle: l10n.repLoginSubtitle,
      children: [
        PhoneFieldCustom(
          label: l10n.phoneLabel,
          onChanged: (p) => _phone = p.completeNumber,
          errorText: _phoneError,
        ),
        const SizedBox(height: 24),
        ButtonCustom.primary(text: l10n.continueButton, onPressed: _continue),
        const Divider(height: 32),
        ButtonCustom.secondary(
          text: l10n.repRegisterButton,
          onPressed: () => context.pushNamed(AppRoutes.repRegisterName),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => context.pushNamed(AppRoutes.repInviteName),
            child: TextCustom(
              text: l10n.repHaveInvite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

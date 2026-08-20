import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Post-registration wait screen: the account is PENDING until Sapbaq verifies
/// the applicant and approves (Mosque Representative spec §3/§9). No session
/// exists yet — the rep returns to login once approved.
class RepPendingScreen extends StatelessWidget {
  const RepPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 72,
                color: context.colors.primary,
              ),
              const SizedBox(height: 24),
              TextCustom.heading(
                text: l10n.repPendingTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextCustom(
                text: l10n.repPendingBody,
                fontSize: 14,
                color: context.colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ButtonCustom.primary(
                text: l10n.repBackToLogin,
                onPressed: () => context.goNamed(AppRoutes.repLoginName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

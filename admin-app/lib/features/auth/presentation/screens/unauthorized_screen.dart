import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Shown when a signed-in account is neither ADMIN nor DRIVER — this app is for
/// staff only. Offers a way back to the login screen.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: ColorsCustom.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: ColorsCustom.error,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                TextCustom.subheading(
                  text: l10n.unauthorizedTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextCustom.body(
                  text: l10n.unauthorizedDesc,
                  color: ColorsCustom.textSecondary,
                  fontSize: 15,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ButtonCustom.primary(
                  text: l10n.backToLogin,
                  width: 220,
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthLogoutRequested()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

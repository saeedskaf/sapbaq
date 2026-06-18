import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: context.colors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: ColorsCustom.success,
                ),
              ),
              const SizedBox(height: 28),
              TextCustom.heading(
                text: l10n.orderSuccessTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextCustom.body(
                text: l10n.orderSuccessDesc,
                color: context.colors.textSecondary,
                fontSize: 15,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ButtonCustom.primary(
                text: l10n.backToHome,
                onPressed: () => context.goNamed(AppRoutes.homeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

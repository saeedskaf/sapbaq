import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/resend_cooldown.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// A centered "Resend code" button that shows a live countdown while
/// [cooldown] is active, driven by the server's escalating backoff.
class ResendButton extends StatelessWidget {
  final ResendCooldown cooldown;
  final bool enabled;
  final VoidCallback onResend;

  const ResendButton({
    super.key,
    required this.cooldown,
    required this.enabled,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ValueListenableBuilder<int>(
        valueListenable: cooldown,
        builder: (context, remaining, _) {
          final active = remaining > 0;
          return TextButton(
            onPressed: (!enabled || active) ? null : onResend,
            child: TextCustom(
              text: active ? l10n.resendCodeIn(remaining) : l10n.resendCode,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? context.colors.textHint : context.colors.primary,
            ),
          );
        },
      ),
    );
  }
}

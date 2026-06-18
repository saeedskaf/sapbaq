import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Gate an account-bound action behind sign-in. Returns true if the user is
/// authenticated; for a guest, shows a login-required sheet and returns false.
bool ensureAuthenticated(BuildContext context) {
  if (context.read<AuthBloc>().state.status == AuthStatus.authenticated) {
    return true;
  }
  showLoginRequiredSheet(context);
  return false;
}

void showLoginRequiredSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _LoginRequiredSheet(),
  );
}

/// Full-screen prompt shown in place of an account-bound tab (Orders / Profile)
/// while browsing as a guest. Offers sign-in / create-account.
class GuestGateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const GuestGateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.colors.primary, size: 44),
            ),
            const SizedBox(height: 20),
            TextCustom.subheading(text: title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextCustom(
              text: message,
              fontSize: 14,
              color: context.colors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ButtonCustom.primary(
              text: l10n.loginButton,
              onPressed: () => context.pushNamed(AppRoutes.loginName),
            ),
            const SizedBox(height: 10),
            ButtonCustom.secondary(
              text: l10n.createAccountLink,
              onPressed: () => context.pushNamed(AppRoutes.signupName),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequiredSheet extends StatelessWidget {
  const _LoginRequiredSheet();

  void _go(BuildContext context, String routeName) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: context.colors.primary,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextCustom.subheading(
            text: l10n.loginRequiredTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextCustom(
            text: l10n.loginRequiredDesc,
            fontSize: 14,
            color: context.colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ButtonCustom.primary(
            text: l10n.loginButton,
            onPressed: () => _go(context, AppRoutes.loginName),
          ),
          const SizedBox(height: 10),
          ButtonCustom.secondary(
            text: l10n.createAccountLink,
            onPressed: () => _go(context, AppRoutes.signupName),
          ),
        ],
      ),
    );
  }
}

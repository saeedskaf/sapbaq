import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/settings/settings_cubit.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Shared profile tab: an identity header, then a logout action.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.profileTitle)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              floatingNavBarClearance(context),
            ),
            children: [
              _IdentityCard(user: user),
              const SizedBox(height: 16),
              _LanguageTile(
                onTap: () => context.pushNamed(AppRoutes.settingsLanguageName),
              ),
              const SizedBox(height: 12),
              _AppearanceTile(
                onTap: () =>
                    context.pushNamed(AppRoutes.settingsAppearanceName),
              ),
              const SizedBox(height: 16),
              _LogoutTile(
                onTap: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final User? user;
  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final u = user;
    final name = u?.fullName ?? '';
    final phone = u?.phone ?? '';
    final role = u?.roleDisplay ?? '';
    final governorate = u?.governorate?.name ?? '';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: name.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: context.colors.primary,
                  )
                : TextCustom(
                    text: name.characters.first,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.colors.primary,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: name.isEmpty ? l10n.userFallback : name,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextCustom(
                    text: governorate.isEmpty ? role : '$role · $governorate',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextCustom(
                    text: phone,
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the language selection screen. Shows the current UI language as its
/// trailing value.
class _LanguageTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LanguageTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.translate_rounded,
              color: context.colors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: l10n.settingsLanguage,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextCustom(
            text: isArabic ? l10n.languageArabic : l10n.languageEnglish,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textHint,
            size: 22,
          ),
        ],
      ),
    );
  }
}

/// Opens the appearance (light/dark) screen. Shows the current theme mode as
/// its trailing value.
class _AppearanceTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AppearanceTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mode = context.watch<SettingsCubit>().state.themeMode;
    final modeLabel = switch (mode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
    };
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.dark_mode_rounded,
              color: context.colors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: l10n.settingsAppearance,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextCustom(
            text: modeLabel,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textHint,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorsCustom.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: ColorsCustom.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: l10n.logout,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ColorsCustom.error,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textHint,
            size: 22,
          ),
        ],
      ),
    );
  }
}

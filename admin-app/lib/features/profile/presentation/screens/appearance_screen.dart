import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/settings/settings_cubit.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Appearance settings: Match device / Light / Dark. Selecting an option
/// applies it instantly across the app via [SettingsCubit].
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.appearanceTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          final cubit = context.read<SettingsCubit>();
          final mode = settings.themeMode;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ThemeTile(
                      icon: Icons.brightness_auto_rounded,
                      label: l10n.themeSystem,
                      selected: mode == ThemeMode.system,
                      onTap: () => cubit.setThemeMode(ThemeMode.system),
                    ),
                    _divider(context),
                    _ThemeTile(
                      icon: Icons.light_mode_rounded,
                      label: l10n.themeLight,
                      selected: mode == ThemeMode.light,
                      onTap: () => cubit.setThemeMode(ThemeMode.light),
                    ),
                    _divider(context),
                    _ThemeTile(
                      icon: Icons.dark_mode_rounded,
                      label: l10n.themeDark,
                      selected: mode == ThemeMode.dark,
                      onTap: () => cubit.setThemeMode(ThemeMode.dark),
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

  Widget _divider(BuildContext context) =>
      Divider(height: 1, color: context.colors.border);
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
                child: Icon(icon, color: context.colors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextCustom(
                  text: label,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: context.colors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

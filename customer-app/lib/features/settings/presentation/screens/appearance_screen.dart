import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/settings/settings_cubit.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/settings/presentation/widgets/settings_option_tile.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Appearance settings: Light / Dark / Match-device. Selecting an option
/// applies it instantly and persists it via [SettingsCubit].
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsOptionGroup(
                children: [
                  SettingsOptionTile(
                    icon: Icons.light_mode_outlined,
                    label: l10n.themeLight,
                    selected: settings.themeMode == ThemeMode.light,
                    onTap: () => cubit.setThemeMode(ThemeMode.light),
                  ),
                  SettingsOptionTile(
                    icon: Icons.dark_mode_outlined,
                    label: l10n.themeDark,
                    selected: settings.themeMode == ThemeMode.dark,
                    onTap: () => cubit.setThemeMode(ThemeMode.dark),
                  ),
                  SettingsOptionTile(
                    icon: Icons.brightness_auto_outlined,
                    label: l10n.themeSystem,
                    selected: settings.themeMode == ThemeMode.system,
                    onTap: () => cubit.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

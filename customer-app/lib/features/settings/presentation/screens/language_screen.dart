import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/settings/settings_cubit.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/settings/presentation/widgets/settings_option_tile.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Language settings: Arabic / English. Selecting a language applies it
/// instantly (rebuilds the app + flips RTL/LTR) and updates the API
/// `Accept-Language` for subsequent requests, via [SettingsCubit].
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.languageTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          final cubit = context.read<SettingsCubit>();
          final lang = settings.locale.languageCode;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsOptionGroup(
                children: [
                  SettingsOptionTile(
                    icon: Icons.translate_rounded,
                    label: l10n.languageArabic,
                    selected: lang == 'ar',
                    onTap: () => cubit.setLocale(const Locale('ar')),
                  ),
                  SettingsOptionTile(
                    icon: Icons.translate_rounded,
                    label: l10n.languageEnglish,
                    selected: lang == 'en',
                    onTap: () => cubit.setLocale(const Locale('en')),
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

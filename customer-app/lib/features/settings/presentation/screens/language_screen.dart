import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/settings/settings_cubit.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Language settings: Arabic / English. Selecting a language applies it
/// instantly (rebuilds the app + flips RTL/LTR) and updates the API
/// `Accept-Language` for subsequent requests, via [SettingsCubit].
///
/// The tiles here are deliberately local rather than the shared
/// `SettingsOptionTile`: this screen mirrors the admin app's language screen
/// (shadowed borderless card, full-width divider, a check only on the selected
/// row), while the shared tile keeps the bordered look the appearance and
/// notification-preferences screens use.
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
              _LanguageCard(
                child: Column(
                  children: [
                    _LanguageTile(
                      label: l10n.languageArabic,
                      selected: lang == 'ar',
                      onTap: () => cubit.setLocale(const Locale('ar')),
                    ),
                    Divider(height: 1, color: context.colors.border),
                    _LanguageTile(
                      label: l10n.languageEnglish,
                      selected: lang == 'en',
                      onTap: () => cubit.setLocale(const Locale('en')),
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
}

/// Borderless panel lifted by a single soft shadow — the admin app's card
/// surface, reproduced here so both language screens read identically.
class _LanguageCard extends StatelessWidget {
  final Widget child;
  const _LanguageCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Material(color: context.colors.surface, child: child),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
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
                child: Icon(
                  Icons.translate_rounded,
                  color: context.colors.primary,
                  size: 18,
                ),
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

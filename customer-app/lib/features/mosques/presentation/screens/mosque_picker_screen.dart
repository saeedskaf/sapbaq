import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_browse_view.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Mosque chooser for the "specific mosque" donation destination. Uses the same
/// [MosqueBrowseView] (search + governorate → area → mosques) as the mosques
/// list tab, but tapping a row pops with the mosque as a [DonationDestination]
/// instead of opening its detail. No map, no favourites, no donate button — it
/// is purely a picker.
class MosquePickerScreen extends StatelessWidget {
  const MosquePickerScreen({super.key});

  void _pick(BuildContext context, Mosque mosque) {
    Navigator.of(context).pop(
      DonationDestination(
        mosqueId: mosque.id,
        label: mosque.name,
        isMostNeeded: mosque.isMostNeeded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.pickMosqueTitle)),
      body: MosqueBrowseView(
        onMosqueTap: (mosque) => _pick(context, mosque),
        trailingBuilder: (_) => Icon(
          Icons.radio_button_unchecked_rounded,
          color: context.colors.textHint,
          size: 22,
        ),
      ),
    );
  }
}

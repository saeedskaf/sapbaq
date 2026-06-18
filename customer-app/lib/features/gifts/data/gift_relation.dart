import 'package:sapbaq/l10n/app_localizations.dart';

/// Arabic label for a `relation_type` value (read-only display; the value is
/// inferred server-side from the chosen gift category).
String giftRelationLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'FATHER':
      return l10n.relFather;
    case 'MOTHER':
      return l10n.relMother;
    case 'HUSBAND':
      return l10n.relHusband;
    case 'WIFE':
      return l10n.relWife;
    case 'SON':
      return l10n.relSon;
    case 'DAUGHTER':
      return l10n.relDaughter;
    case 'BROTHER':
      return l10n.relBrother;
    case 'SISTER':
      return l10n.relSister;
    case 'FRIEND':
      return l10n.relFriend;
    case 'GENERAL':
    default:
      return l10n.relGeneral;
  }
}

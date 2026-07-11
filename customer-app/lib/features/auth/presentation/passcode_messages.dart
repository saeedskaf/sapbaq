import 'package:sapbaq/core/utils/passcode_rules.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Maps a [PasscodeIssue] to a localized, display-ready message.
String passcodeIssueMessage(AppLocalizations l10n, PasscodeIssue issue) {
  return switch (issue) {
    PasscodeIssue.none => '',
    PasscodeIssue.length => l10n.passcodeLength,
    PasscodeIssue.notDigits => l10n.passcodeLength,
    PasscodeIssue.repeated => l10n.passcodeTooSimple,
    PasscodeIssue.sequential => l10n.passcodeTooSimple,
  };
}

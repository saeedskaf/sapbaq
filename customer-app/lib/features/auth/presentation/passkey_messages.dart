import 'package:sapbaq/features/auth/data/passkey_service.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Localized, display-ready message for a platform passkey failure.
String passkeyFailureMessage(AppLocalizations l10n, PasskeyFailure failure) {
  switch (failure) {
    case PasskeyFailure.noCredentials:
      return l10n.passkeyNoneOnDevice;
    case PasskeyFailure.notSupported:
      return l10n.passkeyNotSupported;
    case PasskeyFailure.unknown:
      return l10n.passkeyError;
  }
}

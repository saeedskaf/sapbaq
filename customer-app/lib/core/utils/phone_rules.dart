/// Phone acceptance for the current phase.
///
/// Sapbaq_AUTH_Flow §3: Kuwait (+965) only in Phase 1, but the check is written
/// against a list so enabling more GCC dial codes later is a one-line change,
/// not a rework. Each entry maps a dial code to the national number length.
const Map<String, int> kSupportedDialCodes = {
  '+965': 8, // Kuwait
};

enum PhoneIssue { none, empty, unsupportedCountry, length }

/// Validate a full international number (e.g. `+96512345678`) against the
/// supported dial codes.
PhoneIssue checkSupportedPhone(String completeNumber) {
  final number = completeNumber.trim();
  if (number.isEmpty) return PhoneIssue.empty;
  for (final entry in kSupportedDialCodes.entries) {
    if (number.startsWith(entry.key)) {
      final national = number.substring(entry.key.length);
      return national.length == entry.value
          ? PhoneIssue.none
          : PhoneIssue.length;
    }
  }
  return PhoneIssue.unsupportedCountry;
}

bool isSupportedPhone(String completeNumber) =>
    checkSupportedPhone(completeNumber) == PhoneIssue.none;

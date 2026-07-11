/// Client-side strength check for the 4-digit passcode.
///
/// Mirrors what banking apps reject up front (all-same, simple runs) so the
/// user gets instant feedback; the backend still enforces its own policy. The
/// UI maps [PasscodeIssue] to a localized message.
enum PasscodeIssue { none, length, notDigits, repeated, sequential }

const int kPasscodeLength = 4;

PasscodeIssue checkPasscode(String code) {
  if (code.length != kPasscodeLength) return PasscodeIssue.length;
  if (!RegExp(r'^\d+$').hasMatch(code)) return PasscodeIssue.notDigits;

  final digits = code.split('').map(int.parse).toList();

  // All identical → 0000, 1111, …
  if (digits.every((d) => d == digits.first)) return PasscodeIssue.repeated;

  // Strictly ascending or descending run of consecutive digits → 1234, 6543.
  final ascending = _isRun(digits, 1);
  final descending = _isRun(digits, -1);
  if (ascending || descending) return PasscodeIssue.sequential;

  return PasscodeIssue.none;
}

bool isPasscodeAcceptable(String code) => checkPasscode(code) == PasscodeIssue.none;

bool _isRun(List<int> digits, int step) {
  for (var i = 1; i < digits.length; i++) {
    if (digits[i] - digits[i - 1] != step) return false;
  }
  return true;
}

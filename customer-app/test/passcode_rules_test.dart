import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/utils/passcode_rules.dart';

void main() {
  group('checkPasscode', () {
    test('accepts a non-trivial 4-digit code', () {
      expect(checkPasscode('1357'), PasscodeIssue.none);
      expect(checkPasscode('2846'), PasscodeIssue.none);
      expect(isPasscodeAcceptable('1357'), isTrue);
    });

    test('rejects the wrong length', () {
      expect(checkPasscode('123'), PasscodeIssue.length);
      expect(checkPasscode('12345'), PasscodeIssue.length);
      expect(checkPasscode(''), PasscodeIssue.length);
    });

    test('rejects non-digits', () {
      expect(checkPasscode('12a4'), PasscodeIssue.notDigits);
    });

    test('rejects all-identical digits', () {
      expect(checkPasscode('0000'), PasscodeIssue.repeated);
      expect(checkPasscode('9999'), PasscodeIssue.repeated);
    });

    test('rejects ascending and descending runs', () {
      expect(checkPasscode('1234'), PasscodeIssue.sequential);
      expect(checkPasscode('6789'), PasscodeIssue.sequential);
      expect(checkPasscode('4321'), PasscodeIssue.sequential);
      expect(checkPasscode('9876'), PasscodeIssue.sequential);
    });

    test('allows near-sequences that are not consecutive', () {
      expect(checkPasscode('1243'), PasscodeIssue.none);
      expect(checkPasscode('1357'), PasscodeIssue.none);
    });
  });
}

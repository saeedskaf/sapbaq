import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/utils/phone_rules.dart';

void main() {
  group('checkSupportedPhone', () {
    test('accepts a well-formed Kuwait number (+965 + 8 digits)', () {
      expect(checkSupportedPhone('+96512345678'), PhoneIssue.none);
      expect(isSupportedPhone('+96550001111'), isTrue);
    });

    test('flags an empty number', () {
      expect(checkSupportedPhone(''), PhoneIssue.empty);
    });

    test('rejects an unsupported country', () {
      expect(checkSupportedPhone('+9715012345678'), PhoneIssue.unsupportedCountry);
      expect(checkSupportedPhone('+11234567890'), PhoneIssue.unsupportedCountry);
    });

    test('rejects a Kuwait number of the wrong length', () {
      expect(checkSupportedPhone('+9651234567'), PhoneIssue.length); // 7 digits
      expect(checkSupportedPhone('+965123456789'), PhoneIssue.length); // 9 digits
    });
  });
}

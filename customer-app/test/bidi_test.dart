import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/utils/bidi.dart';

void main() {
  test('ltrIsolate wraps a phone in an LTR isolate (U+2066 … U+2069)', () {
    const phone = '+96512345678';
    final wrapped = ltrIsolate(phone);

    expect(wrapped.codeUnitAt(0), 0x2066); // LEFT-TO-RIGHT ISOLATE
    expect(wrapped.codeUnitAt(wrapped.length - 1), 0x2069); // POP DIRECTIONAL
    expect(wrapped.contains(phone), isTrue);
  });

  test('ltrIsolate leaves an empty string untouched', () {
    expect(ltrIsolate(''), '');
  });
}

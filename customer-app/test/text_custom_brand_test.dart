import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

void main() {
  testWidgets('brand wordmark renders in Tajawal inside Cairo Arabic text', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: TextCustom(
          text: 'مرحبًا بك في ${TextCustom.brandWordmark}',
          color: Colors.black,
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.byType(Text));
    final children = (textWidget.textSpan! as TextSpan).children!
        .cast<TextSpan>();

    expect(children.length, 2);
    // Surrounding Arabic copy uses Cairo…
    expect(children[0].text, 'مرحبًا بك في ');
    expect(children[0].style!.fontFamily, startsWith('Cairo'));
    // …the wordmark stays Tajawal, matching the logo.
    expect(children[1].text, TextCustom.brandWordmark);
    expect(children[1].style!.fontFamily, startsWith('Tajawal'));
  });

  testWidgets('shadda spellings normalize to the Tajawal wordmark', (
    tester,
  ) async {
    for (final spelling in ['سَبّاق', 'سبّاق']) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextCustom(text: 'تطبيق $spelling', color: Colors.black),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      final children = (textWidget.textSpan! as TextSpan).children!
          .cast<TextSpan>();

      expect(children.length, 2, reason: 'spelling: $spelling');
      expect(children[0].text, 'تطبيق ');
      expect(children[0].style!.fontFamily, startsWith('Cairo'));
      // Whatever the source spelling, it renders as the elongated wordmark.
      expect(children[1].text, TextCustom.brandWordmark);
      expect(children[1].style!.fontFamily, startsWith('Tajawal'));
    }
  });

  testWidgets('plain سباق (no shadda) is left as ordinary Cairo prose', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: TextCustom(text: 'سباق الخيل', color: Colors.black),
      ),
    );

    final textWidget = tester.widget<Text>(find.byType(Text));
    expect(textWidget.textSpan, isNull); // not treated as the brand
    expect(textWidget.data, 'سباق الخيل');
    expect(textWidget.style!.fontFamily, startsWith('Cairo'));
  });

  testWidgets('plain Arabic text (no brand) is a single Cairo run', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: TextCustom(text: 'مرحبًا بك', color: Colors.black),
      ),
    );

    final textWidget = tester.widget<Text>(find.byType(Text));
    expect(textWidget.textSpan, isNull); // plain Text, not Text.rich
    expect(textWidget.data, 'مرحبًا بك');
    expect(textWidget.style!.fontFamily, startsWith('Cairo'));
  });

  testWidgets('Latin text uses Poppins', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TextCustom(text: 'Sapbaq', color: Colors.black),
      ),
    );

    final textWidget = tester.widget<Text>(find.byType(Text));
    expect(textWidget.style!.fontFamily, startsWith('Poppins'));
  });
}

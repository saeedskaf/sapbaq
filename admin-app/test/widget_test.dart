import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

void main() {
  testWidgets('Arabic localization loads and lays out RTL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(body: Text(l10n.comingSoon));
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('قريبًا'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('قريبًا'))),
      TextDirection.rtl,
    );
  });
}

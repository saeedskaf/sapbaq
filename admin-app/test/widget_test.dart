import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/core/theme/app_theme.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

void main() {
  test('light and dark themes register their ThemeColors tokens', () {
    final light = AppTheme.light.extension<ThemeColors>()!;
    expect(light.background, ColorsCustom.background);
    expect(light.surface, ColorsCustom.surface);
    expect(light.primary, ColorsCustom.primary);

    final dark = AppTheme.dark.extension<ThemeColors>()!;
    expect(dark.background, ColorsCustom.darkBackground);
    expect(dark.surface, ColorsCustom.darkSurface);
    expect(dark.primary, ColorsCustom.primaryOnDark);
  });

  testWidgets('context.colors resolves the active theme', (tester) async {
    late ThemeColors resolved;
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: AppTheme.dark,
          child: Builder(
            builder: (context) {
              resolved = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(resolved.background, ColorsCustom.darkBackground);
    expect(resolved.primary, ColorsCustom.primaryOnDark);
  });

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

  testWidgets('English localization loads and lays out LTR', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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

    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Coming soon'))),
      TextDirection.ltr,
    );
  });

  // TextCustom's default `start` alignment must follow the UI direction, not
  // the script: left in English (LTR), right in Arabic (RTL). Forcing it to the
  // right (the old behavior) shoved every default-aligned label to the wrong
  // edge in the English layout.
  Future<TextAlign?> pumpDefaultAlignment(
    WidgetTester tester,
    TextDirection direction,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Theme(
            data: AppTheme.light,
            child: const Scaffold(body: TextCustom(text: 'Dashboard')),
          ),
        ),
      ),
    );
    return tester.widget<Text>(find.text('Dashboard')).textAlign;
  }

  testWidgets('TextCustom default alignment is left in LTR', (tester) async {
    expect(
      await pumpDefaultAlignment(tester, TextDirection.ltr),
      TextAlign.left,
    );
  });

  testWidgets('TextCustom default alignment is right in RTL', (tester) async {
    expect(
      await pumpDefaultAlignment(tester, TextDirection.rtl),
      TextAlign.right,
    );
  });
}

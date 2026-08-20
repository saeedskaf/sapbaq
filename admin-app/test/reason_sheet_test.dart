import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/core/theme/app_theme.dart';
import 'package:sapbaq_admin/core/widgets/reason_sheet.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

void main() {
  /// Pumps a button that opens the sheet and records whatever it resolves to.
  /// [result] stays absent until the sheet actually closes.
  Future<({List<String?> result})> openSheet(
    WidgetTester tester, {
    bool required = true,
    String? errorText,
  }) async {
    final result = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result.add(
                    await ReasonSheet.show(
                      context,
                      title: l10n.approvalRejectTitle,
                      hint: l10n.approvalRejectHint,
                      confirmLabel: l10n.confirmReject,
                      required: required,
                      errorText: errorText,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (result: result);
  }

  Finder confirmButton(WidgetTester tester) {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TextField)),
    )!;
    return find.widgetWithText(ElevatedButton, l10n.confirmReject);
  }

  testWidgets('required: confirming while empty keeps the sheet open', (
    tester,
  ) async {
    final harness = await openSheet(tester);

    await tester.tap(confirmButton(tester));
    await tester.pumpAndSettle();

    expect(
      harness.result,
      isEmpty,
      reason: 'the sheet must not resolve while the reason is missing',
    );
    expect(find.byType(TextField), findsOneWidget, reason: 'still open');
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
  });

  testWidgets('required: whitespace alone does not count as a reason', (
    tester,
  ) async {
    final harness = await openSheet(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(confirmButton(tester));
    await tester.pumpAndSettle();

    expect(harness.result, isEmpty);
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
  });

  testWidgets('required: typing clears the error and confirm then works', (
    tester,
  ) async {
    final harness = await openSheet(tester);

    await tester.tap(confirmButton(tester));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'سبب الرفض');
    await tester.pump();
    expect(
      find.text('هذا الحقل مطلوب'),
      findsNothing,
      reason: 'error should clear as soon as the user types',
    );

    await tester.tap(confirmButton(tester));
    await tester.pumpAndSettle();
    expect(harness.result, ['سبب الرفض']);
  });

  testWidgets('required: the reason is trimmed', (tester) async {
    final harness = await openSheet(tester);

    await tester.enterText(find.byType(TextField), '  سبب  ');
    await tester.tap(confirmButton(tester));
    await tester.pumpAndSettle();

    expect(harness.result, ['سبب']);
  });

  testWidgets('a custom errorText replaces the generic one', (tester) async {
    await openSheet(tester, errorText: 'أدخل بيان الإنجاز');

    await tester.tap(confirmButton(tester));
    await tester.pumpAndSettle();

    expect(find.text('أدخل بيان الإنجاز'), findsOneWidget);
    expect(find.text('هذا الحقل مطلوب'), findsNothing);
  });

  testWidgets('cancelling resolves to null, not an empty string', (
    tester,
  ) async {
    final harness = await openSheet(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(TextField)))!;

    await tester.enterText(find.byType(TextField), 'مكتوب');
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.cancelButton));
    await tester.pumpAndSettle();

    expect(
      harness.result,
      [null],
      reason: 'null must mean aborted, so callers can tell it from a reason',
    );
  });

  testWidgets('optional: confirming while empty resolves to an empty string', (
    tester,
  ) async {
    final harness = await openSheet(tester, required: false);

    await tester.tap(confirmButton(tester));
    await tester.pumpAndSettle();

    expect(
      harness.result,
      [''],
      reason: 'an optional sheet distinguishes a blank confirm from a cancel',
    );
    expect(find.text('هذا الحقل مطلوب'), findsNothing);
  });
}

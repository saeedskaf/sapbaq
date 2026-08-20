import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/core/theme/app_theme.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/models/mosque_filters.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/screens/mosque_picker_screen.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Serves one governorate → one area → one mosque, and records the filters it
/// was asked for so the drill-down's scoping can be asserted.
class _FakeMosquesRepository extends MosquesRepository {
  _FakeMosquesRepository() : super(Dio());

  String? filtersGovernorate;
  String? mosquesGovernorate;
  String? mosquesArea;

  @override
  Future<MosqueFilters> fetchFilters({
    String? governorate,
    String? area,
  }) async {
    filtersGovernorate = governorate;
    if (governorate == null) {
      return const MosqueFilters(
        governorates: [FilterOption(value: 'العاصمة', count: 2)],
      );
    }
    return const MosqueFilters(
      areas: [FilterOption(value: 'الشامية', count: 1)],
    );
  }

  @override
  Future<PaginatedResponse<Mosque>> fetchMosques({
    int page = 1,
    String? search,
    String? governorate,
    String? area,
    String? block,
    bool mostNeeded = false,
  }) async {
    mosquesGovernorate = governorate;
    mosquesArea = area;
    return const PaginatedResponse(
      count: 1,
      results: [Mosque(id: 7, name: 'مسجد الشامية', area: 'الشامية')],
    );
  }
}

Future<void> _pumpPicker(
  WidgetTester tester,
  _FakeMosquesRepository repo,
  ValueChanged<DonationDestination?> onPop,
) async {
  await tester.pumpWidget(
    RepositoryProvider<MosquesRepository>.value(
      value: repo,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final picked = await Navigator.of(context)
                      .push<DonationDestination>(
                        MaterialPageRoute(
                          builder: (_) => const MosquePickerScreen(),
                        ),
                      );
                  onPop(picked);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('picker walks governorate → area → mosque and pops the choice', (
    tester,
  ) async {
    final repo = _FakeMosquesRepository();
    DonationDestination? picked;
    await _pumpPicker(tester, repo, (d) => picked = d);

    // Level 1: governorates.
    expect(find.text('اختر المحافظة'), findsOneWidget);
    expect(find.text('العاصمة'), findsOneWidget);
    await tester.tap(find.text('العاصمة'));
    await tester.pumpAndSettle();

    // Level 2: areas, scoped to the chosen governorate.
    expect(find.text('اختر المنطقة'), findsOneWidget);
    expect(repo.filtersGovernorate, 'العاصمة');
    await tester.tap(find.text('الشامية'));
    await tester.pumpAndSettle();

    // Level 3: mosques, scoped to governorate + area.
    expect(repo.mosquesGovernorate, 'العاصمة');
    expect(repo.mosquesArea, 'الشامية');
    await tester.tap(find.text('مسجد الشامية'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.mosqueId, 7);
    expect(picked!.label, 'مسجد الشامية');
  });

  testWidgets('picker steps back up from areas to governorates', (
    tester,
  ) async {
    final repo = _FakeMosquesRepository();
    await _pumpPicker(tester, repo, (_) {});

    await tester.tap(find.text('العاصمة'));
    await tester.pumpAndSettle();
    expect(find.text('اختر المنطقة'), findsOneWidget);

    // The breadcrumb doubles as the back control.
    await tester.tap(find.text('العاصمة'));
    await tester.pumpAndSettle();
    expect(find.text('اختر المحافظة'), findsOneWidget);
  });
}

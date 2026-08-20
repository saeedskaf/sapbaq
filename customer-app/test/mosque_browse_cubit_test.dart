import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/models/mosque_filters.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/mosque_browse_cubit.dart';

/// Hands out a completer per request so tests can resolve responses in any
/// order and reproduce a slow network.
class _ControllableRepository extends MosquesRepository {
  _ControllableRepository() : super(Dio());

  final filterCalls = <String?, Completer<MosqueFilters>>{};
  final mosqueCalls = <Completer<PaginatedResponse<Mosque>>>[];

  @override
  Future<MosqueFilters> fetchFilters({String? governorate, String? area}) {
    final completer = Completer<MosqueFilters>();
    filterCalls[governorate] = completer;
    return completer.future;
  }

  @override
  Future<PaginatedResponse<Mosque>> fetchMosques({
    int page = 1,
    String? search,
    String? governorate,
    String? area,
    String? block,
    bool mostNeeded = false,
  }) {
    final completer = Completer<PaginatedResponse<Mosque>>();
    mosqueCalls.add(completer);
    return completer.future;
  }
}

MosqueFilters _areas(List<String> values) =>
    MosqueFilters(areas: [for (final v in values) FilterOption(value: v)]);

void main() {
  test('a slow response for an abandoned governorate cannot overwrite the '
      'newer one', () async {
    final repo = _ControllableRepository();
    final cubit = MosqueBrowseCubit(repo);

    cubit.selectGovernorate('العاصمة');
    cubit.selectGovernorate('حولي');

    // The second tap's areas arrive first, then the abandoned first tap's.
    repo.filterCalls['حولي']!.complete(_areas(['السالمية']));
    await Future<void>.delayed(Duration.zero);
    repo.filterCalls['العاصمة']!.complete(_areas(['الشامية']));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.governorate, 'حولي');
    expect(
      cubit.state.options.map((o) => o.value),
      ['السالمية'],
      reason: 'the stale response for العاصمة must not paint under حولي',
    );
    await cubit.close();
  });

  test(
    'a slow mosque page cannot land on a level the user already left',
    () async {
      final repo = _ControllableRepository();
      final cubit = MosqueBrowseCubit(repo);

      // Drill to a governorate's areas, then into an area's mosques.
      cubit.selectGovernorate('العاصمة');
      repo.filterCalls['العاصمة']!.complete(_areas(['الشامية']));
      await Future<void>.delayed(Duration.zero);
      cubit.selectArea('الشامية');

      // The user backs out to the areas level while the mosques are in flight.
      cubit.back();
      repo.mosqueCalls.first.complete(
        const PaginatedResponse(
          count: 1,
          results: [Mosque(id: 1, name: 'مسجد')],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // The abandoned mosque page must not flip the areas level to "success"
      // with no options — that renders a bogus "no areas" empty state.
      expect(cubit.state.step, MosqueBrowseStep.area);
      expect(
        cubit.state.status,
        LoadStatus.loading,
        reason: 'still waiting on the areas request',
      );
      await cubit.close();
    },
  );
}

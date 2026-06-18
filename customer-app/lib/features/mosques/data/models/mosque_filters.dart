import 'package:equatable/equatable.dart';

/// One filter facet value with its mosque count (e.g. governorate "العاصمة" × 322).
class FilterOption extends Equatable {
  final String value;
  final int count;

  const FilterOption({required this.value, this.count = 0});

  @override
  List<Object?> get props => [value, count];
}

/// Cascading filter facets from `GET /mosques/filters/`. When fetched with a
/// `governorate` (and optionally `area`), [areas]/[blocks] are scoped to it.
class MosqueFilters extends Equatable {
  final List<FilterOption> governorates;
  final List<FilterOption> areas;
  final List<FilterOption> blocks;

  const MosqueFilters({
    this.governorates = const [],
    this.areas = const [],
    this.blocks = const [],
  });

  static List<FilterOption> _parse(dynamic list, String key) {
    if (list is! List) return const [];
    return list
        .map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return FilterOption(
            value: (m[key] ?? '').toString(),
            count: m['count'] as int? ?? 0,
          );
        })
        .where((o) => o.value.isNotEmpty)
        .toList();
  }

  factory MosqueFilters.fromJson(Map<String, dynamic> json) {
    return MosqueFilters(
      governorates: _parse(json['governorates'], 'governorate'),
      areas: _parse(json['areas'], 'area'),
      blocks: _parse(json['blocks'], 'block'),
    );
  }

  @override
  List<Object?> get props => [governorates, areas, blocks];
}

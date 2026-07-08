import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/showcase/data/models/showcase_item.dart';

/// A titled group of showcase items (`GET /showcase/sections/`, FLUTTER_TASKS
/// item 14). Empty sections aren't returned; items without a section arrive
/// grouped under a synthetic section with `id == 0` ("أخرى"), always last.
class ShowcaseSection extends Equatable {
  final int id;
  final String title;
  final String description;
  final int sortOrder;
  final List<ShowcaseItem> items;

  const ShowcaseSection({
    required this.id,
    required this.title,
    this.description = '',
    this.sortOrder = 0,
    this.items = const [],
  });

  factory ShowcaseSection.fromJson(Map<String, dynamic> json) {
    return ShowcaseSection(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      sortOrder: json['sort_order'] as int? ?? 0,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => ShowcaseItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, title, description, sortOrder, items];
}

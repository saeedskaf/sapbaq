import 'package:equatable/equatable.dart';

/// A public showcase media item (`GET /showcase/`): an admin-uploaded photo or
/// video of charity work. [file] and [thumbnail] are absolute URLs.
class ShowcaseItem extends Equatable {
  final int id;
  final int? section; // owning section id (null = ungrouped)
  final String title;
  final String description;
  final String mediaType; // IMAGE | VIDEO
  final String file;
  final String? thumbnail;
  final int sortOrder;
  final String? createdAt;

  const ShowcaseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaType,
    required this.file,
    this.section,
    this.thumbnail,
    this.sortOrder = 0,
    this.createdAt,
  });

  bool get isVideo => mediaType.toUpperCase() == 'VIDEO';

  factory ShowcaseItem.fromJson(Map<String, dynamic> json) {
    return ShowcaseItem(
      id: json['id'] as int,
      section: json['section'] as int?,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      mediaType: (json['media_type'] ?? 'IMAGE').toString(),
      file: (json['file'] ?? '').toString(),
      thumbnail: json['thumbnail'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    section,
    title,
    description,
    mediaType,
    file,
    thumbnail,
    sortOrder,
    createdAt,
  ];
}

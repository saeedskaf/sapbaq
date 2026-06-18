import 'package:equatable/equatable.dart';

/// One item in a product's media gallery (`media[]` on the product payload):
/// an extra image or a video shown on the detail screen. [file] and
/// [thumbnail] are absolute URLs; [thumbnail] is typically set only for videos
/// (`null` for images). The server returns the list pre-sorted by [sortOrder].
class ProductMedia extends Equatable {
  final int id;
  final String mediaType; // IMAGE | VIDEO
  final String file;
  final String? thumbnail;
  final int sortOrder;

  const ProductMedia({
    required this.id,
    required this.mediaType,
    required this.file,
    this.thumbnail,
    this.sortOrder = 0,
  });

  bool get isVideo => mediaType.toUpperCase() == 'VIDEO';

  factory ProductMedia.fromJson(Map<String, dynamic> json) {
    return ProductMedia(
      id: json['id'] as int,
      mediaType: (json['media_type'] ?? 'IMAGE').toString(),
      file: (json['file'] ?? '').toString(),
      thumbnail: json['thumbnail'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, mediaType, file, thumbnail, sortOrder];
}

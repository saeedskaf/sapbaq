import 'package:equatable/equatable.dart';

/// One ordered section of a CMS page (`/content/{slug}/`). For FAQ pages this
/// is a question (`title`) / answer (`body`) pair; for other pages it's an
/// optional sub-heading shown after the page body.
class ContentSection extends Equatable {
  final int id;
  final String title;
  final String body;
  final int sortOrder;

  const ContentSection({
    required this.id,
    this.title = '',
    this.body = '',
    this.sortOrder = 0,
  });

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, title, body, sortOrder];
}

/// A CMS page. `title`/`body` arrive already localized (per `Accept-Language`);
/// `sections` are sorted by `sort_order`.
class ContentPage extends Equatable {
  final String slug;
  final String title;
  final String body;
  final List<ContentSection> sections;

  const ContentPage({
    required this.slug,
    this.title = '',
    this.body = '',
    this.sections = const [],
  });

  factory ContentPage.fromJson(Map<String, dynamic> json) {
    final sections =
        (json['sections'] as List<dynamic>? ?? const [])
            .map((e) => ContentSection.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ContentPage(
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      sections: sections,
    );
  }

  @override
  List<Object?> get props => [slug, title, body, sections];
}

import 'package:equatable/equatable.dart';

/// Banner campaign type — drives an optional accent badge in the UI.
enum BannerType {
  ramadan,
  eid,
  promotion,
  seasonal,
  general;

  static BannerType fromJson(String? value) => BannerType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => BannerType.general,
  );
}

/// A promotional banner for the home carousel. Named `PromoBanner` to avoid
/// clashing with Flutter's material `Banner` widget. [image] is absolute.
/// [link] may be empty (decorative), an internal path (`/...`), or an external
/// URL (`http...`).
class PromoBanner extends Equatable {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final BannerType type;
  final String link;

  const PromoBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.image,
    this.type = BannerType.general,
    this.link = '',
  });

  bool get hasLink => link.isNotEmpty;

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: json['id'] as int,
    title: (json['title'] ?? '').toString(),
    subtitle: (json['subtitle'] ?? '').toString(),
    image: (json['image'] ?? '').toString(),
    type: BannerType.fromJson(json['banner_type'] as String?),
    link: (json['link'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, title, subtitle, image, type, link];
}

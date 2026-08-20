import 'package:equatable/equatable.dart';

/// Banner campaign type — a seasonal label for presentation only. It says
/// nothing about where a tap goes; that is [PromoBanner.linkType] alone.
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

/// Where tapping a banner goes. A closed set owned by the backend
/// (FLUTTER_CLICKABLE_BANNERS §2) — an unknown value from a newer server is
/// kept as-is and ignored at dispatch, never thrown on.
abstract final class BannerLinkType {
  static const none = 'none';
  static const home = 'home';
  static const mosques = 'mosques';
  static const mosque = 'mosque';
  static const marketplace = 'marketplace';
  static const marketplaceWater = 'marketplace_water';
  static const marketplaceMaintenance = 'marketplace_maintenance';
  static const marketplaceEquipment = 'marketplace_equipment';
  static const products = 'products';
  static const productCategory = 'product_category';
  static const product = 'product';
  static const contentPage = 'content_page';
  static const externalUrl = 'external_url';
}

/// A promotional banner for the home carousel. Named `PromoBanner` to avoid
/// clashing with Flutter's material `Banner` widget. [image] is absolute.
///
/// Navigation is structured, not parsed: [linkType] names the destination and
/// [linkRef] carries whatever that destination needs (an id, a slug, a URL) —
/// always as text, even for numeric ids. [link] is the ready-made `saqia://`
/// string the backend builds from the two; it's kept for diagnostics, and
/// deliberately not used for routing (string-matching a URL is the brittle way).
class PromoBanner extends Equatable {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final BannerType type;
  final String linkType;
  final String linkRef;
  final String link;

  const PromoBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.image,
    this.type = BannerType.general,
    this.linkType = BannerLinkType.none,
    this.linkRef = '',
    this.link = '',
  });

  /// A banner without a destination is decoration — it must not offer a press
  /// affordance.
  bool get isTappable =>
      linkType.isNotEmpty && linkType != BannerLinkType.none && link.isNotEmpty;

  /// [linkRef] parsed as an id, or null when it isn't one. The backend
  /// validates references at creation time, so this is belt-and-braces.
  int? get refId => int.tryParse(linkRef.trim());

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: json['id'] as int,
    title: (json['title'] ?? '').toString(),
    subtitle: (json['subtitle'] ?? '').toString(),
    image: (json['image'] ?? '').toString(),
    type: BannerType.fromJson(json['banner_type'] as String?),
    // An older server build sends neither field; that reads as "no destination"
    // rather than a crash.
    linkType: (json['link_type'] ?? BannerLinkType.none).toString(),
    linkRef: (json['link_ref'] ?? '').toString(),
    link: (json['link'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    image,
    type,
    linkType,
    linkRef,
    link,
  ];
}

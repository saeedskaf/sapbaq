import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/features/banners/data/models/banner.dart';
import 'package:sapbaq/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:sapbaq/features/products/presentation/widgets/product_detail_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a banner's destination (FLUTTER_CLICKABLE_BANNERS §3).
///
/// Switches on `link_type` rather than parsing the `saqia://` string: the type
/// is a closed set the backend owns, while URL matching would break on every
/// path change. A type this build doesn't know — a newer server, an older app —
/// is ignored in silence; a dead tap beats a crashed carousel.
void openBannerLink(BuildContext context, PromoBanner banner) {
  final ref = banner.linkRef.trim();
  switch (banner.linkType) {
    case BannerLinkType.home:
      context.goNamed(AppRoutes.homeName);
    case BannerLinkType.mosques:
      context.goNamed(AppRoutes.mosquesName);
    case BannerLinkType.mosque:
      final id = banner.refId;
      if (id != null) {
        context.pushNamed(
          AppRoutes.mosqueDetailName,
          pathParameters: {'id': '$id'},
        );
      }
    case BannerLinkType.marketplace:
      context.pushNamed(AppRoutes.marketplaceName);
    case BannerLinkType.marketplaceWater:
      _marketplace(context, MarketplaceTab.water);
    case BannerLinkType.marketplaceMaintenance:
      _marketplace(context, MarketplaceTab.maintenance);
    case BannerLinkType.marketplaceEquipment:
      _marketplace(context, MarketplaceTab.equipment);
    case BannerLinkType.products:
      context.pushNamed(AppRoutes.categoryProductsName);
    case BannerLinkType.productCategory:
      final id = banner.refId;
      if (id != null) {
        context.pushNamed(AppRoutes.categoryProductsName, extra: id);
      }
    case BannerLinkType.product:
      final id = banner.refId;
      // Product details are a sheet, not a route — the same quick view the
      // storefront opens.
      if (id != null) showProductDetailSheet(context, id);
    case BannerLinkType.contentPage:
      final name = _contentRouteName(ref);
      if (name != null) context.pushNamed(name);
    case BannerLinkType.externalUrl:
      final uri = Uri.tryParse(ref);
      // Only the external type ever leaves the app, and only over http(s) —
      // never an arbitrary scheme from a server-managed field.
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    case BannerLinkType.none:
    default:
      return;
  }
}

void _marketplace(BuildContext context, MarketplaceTab tab) {
  context.pushNamed(
    AppRoutes.marketplaceName,
    queryParameters: {'tab': tab.slug},
  );
}

/// CMS slugs the app has screens for. An unknown slug (a page added on the
/// backend before the app has a screen) simply doesn't navigate.
String? _contentRouteName(String slug) => switch (slug) {
  'privacy' => AppRoutes.privacyName,
  'terms' => AppRoutes.termsName,
  'about' => AppRoutes.aboutName,
  'faq' => AppRoutes.faqName,
  _ => null,
};

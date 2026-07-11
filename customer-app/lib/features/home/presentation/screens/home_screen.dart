import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/banners/data/banners_repository.dart';
import 'package:sapbaq/features/banners/data/models/banner.dart';
import 'package:sapbaq/features/banners/presentation/bloc/banners_cubit.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Donation entry / discovery screen (Home tab): a greeting header and banner
/// carousel over a soft brand wash, then the two donation paths (a featured
/// gradient card for the most-needed pool, a surface card for a chosen
/// mosque).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _hPad = EdgeInsets.symmetric(horizontal: 20);

  void _onBannerTap(BuildContext context, PromoBanner banner) {
    final l10n = AppLocalizations.of(context)!;
    switch (banner.link) {
      case '/most-needed':
        context.pushNamed(
          AppRoutes.productsName,
          extra: DonationDestination.mostNeeded(label: l10n.mostNeededShort),
        );
      case '/mosques':
        context.goNamed(AppRoutes.mosquesName);
      case '/showcase':
      case '/media':
        context.goNamed(AppRoutes.mediaName);
      default:
        // External URLs open in the browser; unknown internal paths no-op.
        final uri = Uri.tryParse(banner.link);
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) =>
          BannersCubit(context.read<BannersRepository>())..load(),
      child: Scaffold(
        // No SafeArea: the wash paints under the status bar and the whole
        // page scrolls as one piece (the top zone pads itself past the
        // status-bar inset).
        body: ListView(
          padding: EdgeInsets.only(bottom: floatingNavBarClearance(context)),
          children: [
            _TopZone(onBannerTap: (b) => _onBannerTap(context, b)),
            const SizedBox(height: 28),
            Padding(
              padding: _hPad,
              child: TextCustom.subheading(
                text: l10n.donateMethodTitle,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: _hPad,
              child: _FeaturedDonateCard(
                title: l10n.mostNeededShort,
                subtitle: l10n.mostNeededDesc,
                onTap: () => context.pushNamed(
                  AppRoutes.productsName,
                  extra: DonationDestination.mostNeeded(
                    label: l10n.mostNeededShort,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: _hPad,
              child: _DonatePathCard(
                icon: Icons.mosque_rounded,
                title: l10n.chooseMosqueTitle,
                subtitle: l10n.chooseMosqueDesc,
                onTap: () => context.goNamed(AppRoutes.mosquesName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header + banner carousel over a soft brand-tint wash that fades into the
/// scaffold background. Lives inside the scroll view so it moves with the
/// content, and pads itself below the status bar. The tint is theme-aware.
class _TopZone extends StatelessWidget {
  final ValueChanged<PromoBanner> onBannerTap;
  const _TopZone({required this.onBannerTap});

  @override
  Widget build(BuildContext context) {
    final tint = context.colors.primaryTint;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint.withValues(alpha: 0.55), tint.withValues(alpha: 0.0)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12),
        child: Column(
          children: [
            const Padding(
              padding: HomeScreen._hPad,
              child: _HomeHeader(),
            ),
            _BannerSection(onTap: onBannerTap),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state.user?.fullName ?? '';
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom.heading(
                    text: name.isEmpty ? l10n.homeWelcome : l10n.greeting(name),
                    fontSize: 22,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  TextCustom.body(
                    text: l10n.appTagline,
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _NotificationBell(
              onTap: () {
                if (ensureAuthenticated(context)) {
                  context.pushNamed(AppRoutes.notificationsName);
                }
              },
            ),
            const SizedBox(width: 10),
            _ProfileAvatarButton(name: name),
          ],
        );
      },
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: CircleBorder(
        side: BorderSide(color: context.colors.border, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.notifications_none_rounded,
            color: context.colors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Profile entry point in the Home top corner (relocated from the bottom dock).
/// A brand-gradient disc with the user's initial (person icon for guests);
/// opens the profile as a pushed full-screen route. Auto-positions by text
/// direction.
class _ProfileAvatarButton extends StatelessWidget {
  final String name;
  const _ProfileAvatarButton({required this.name});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          color: ColorsCustom.primary,
          shape: BoxShape.circle,
        ),
        child: InkWell(
          onTap: () => context.pushNamed(AppRoutes.profileName),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: name.isEmpty
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: ColorsCustom.textOnPrimary,
                      size: 24,
                    )
                  : TextCustom(
                      text: name.characters.first,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ColorsCustom.textOnPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Banner geometry — a FIXED 2:1 aspect ratio (width:height) so the artwork
// looks identical on every screen size; the height is derived from the card
// width rather than hard-coded. Design banners at 2:1. Shared by the carousel
// and its loading skeleton so the layout doesn't jump when banners arrive.
const double _bannerViewportFraction = 0.9;
const double _bannerCardHPadding = 6; // must match _BannerCard's padding
const double _bannerAspectRatio = 2 / 1;

double _bannerHeightFor(double maxWidth) {
  final cardWidth =
      maxWidth * _bannerViewportFraction - _bannerCardHPadding * 2;
  return cardWidth / _bannerAspectRatio;
}

/// Banner area: a same-geometry pulsing skeleton while loading (so content
/// below doesn't jump when banners arrive), the carousel on success, and
/// nothing when there are no banners (they're non-critical decoration).
class _BannerSection extends StatelessWidget {
  final ValueChanged<PromoBanner> onTap;
  const _BannerSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannersCubit, BannersState>(
      builder: (context, state) {
        final Widget child;
        switch (state.status) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            child = const _BannerSkeleton();
          case LoadStatus.success when state.banners.isNotEmpty:
            child = _BannerCarousel(banners: state.banners, onTap: onTap);
          default:
            return const SizedBox.shrink();
        }
        return Padding(padding: const EdgeInsets.only(top: 20), child: child);
      },
    );
  }
}

/// Gently pulsing placeholder matching the banner card's exact geometry.
class _BannerSkeleton extends StatefulWidget {
  const _BannerSkeleton();

  @override
  State<_BannerSkeleton> createState() => _BannerSkeletonState();
}

class _BannerSkeletonState extends State<_BannerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _bannerHeightFor(constraints.maxWidth);
        return Center(
          child: FadeTransition(
            opacity: _controller,
            child: Container(
              width: constraints.maxWidth * _bannerViewportFraction -
                  _bannerCardHPadding * 2,
              height: height,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final ValueChanged<PromoBanner> onTap;

  const _BannerCarousel({required this.banners, required this.onTap});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: _bannerViewportFraction,
  );
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % widget.banners.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _bannerHeightFor(constraints.maxWidth);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: banners.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final banner = banners[i];
                    return _BannerCard(
                      banner: banner,
                      onTap: banner.hasLink ? () => widget.onTap(banner) : null,
                    );
                  },
                ),
              ),
              if (banners.length > 1)
                PositionedDirectional(
                  bottom: 14,
                  start: 0,
                  end: 0,
                  child: _BannerDots(count: banners.length, index: _index),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Page indicators overlaid on the banner image, wrapped in a translucent pill
/// so they stay legible over any artwork.
class _BannerDots extends StatelessWidget {
  final int count;
  final int index;
  const _BannerDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final VoidCallback? onTap;

  const _BannerCard({required this.banner, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _bannerCardHPadding),
      child: Material(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Image.network(
            banner.image,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : ColoredBox(color: context.colors.surfaceVariant),
            errorBuilder: (_, _, _) => ColoredBox(
              color: context.colors.surfaceVariant,
              child: Icon(
                Icons.image_outlined,
                color: context.colors.textHint,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The flagship donation path (the most-needed pool), rendered as a hero card:
/// brand gradient, a frosted icon chip, an oversized watermark of the same
/// icon, and a forward-arrow affordance. White foregrounds are brand-fixed —
/// they sit on the gradient in both themes.
class _FeaturedDonateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeaturedDonateCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : ColorsCustom.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: ColorsCustom.primary),
              ),
            ),
            PositionedDirectional(
              end: -18,
              bottom: -26,
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 124,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: Colors.white.withValues(alpha: 0.12),
                highlightColor: Colors.white.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextCustom(
                              text: title,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            TextCustom(
                              text: subtitle,
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.85),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        // arrow_forward auto-mirrors under RTL
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The secondary donation entry point (a chosen mosque): a clean full-width
/// surface card with a tinted icon chip, a title with a short description,
/// and a tinted forward-arrow chip.
class _DonatePathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DonatePathCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.colors.border, width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.primaryTint,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: context.colors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        text: title,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      TextCustom(
                        text: subtitle,
                        fontSize: 12.5,
                        color: context.colors.textSecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  // arrow_forward auto-mirrors under RTL
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: context.colors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


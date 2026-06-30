import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/banners/data/banners_repository.dart';
import 'package:sapbaq/features/banners/data/models/banner.dart';
import 'package:sapbaq/features/banners/presentation/bloc/banners_cubit.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Donation entry / discovery screen (Home tab): a greeting header, a banner
/// carousel, then the two donation paths (most-needed pool / a chosen mosque).
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
      // Other internal paths / external URLs aren't wired yet.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) =>
          BannersCubit(context.read<BannersRepository>())..load(),
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.only(
              top: 8,
              bottom: floatingNavBarClearance(context),
            ),
            children: [
              const Padding(padding: _hPad, child: _HomeHeader()),
              BlocBuilder<BannersCubit, BannersState>(
                builder: (context, state) {
                  if (state.status != LoadStatus.success ||
                      state.banners.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _BannerCarousel(
                      banners: state.banners,
                      onTap: (b) => _onBannerTap(context, b),
                    ),
                  );
                },
              ),
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
                child: _DonatePathCard(
                  icon: Icons.volunteer_activism_rounded,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications_none_rounded,
          color: context.colors.primary,
          size: 24,
        ),
      ),
    );
  }
}

/// Profile entry point in the Home top corner (relocated from the bottom dock).
/// Shows the user's initial, or a person icon for guests; opens the profile as
/// a pushed full-screen route. Auto-positions by text direction.
class _ProfileAvatarButton extends StatelessWidget {
  final String name;
  const _ProfileAvatarButton({required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(AppRoutes.profileName),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: name.isEmpty
            ? Icon(
                Icons.person_outline_rounded,
                color: context.colors.primary,
                size: 24,
              )
            : TextCustom(
                text: name.characters.first,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
      ),
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
  // Banner geometry — a FIXED 2:1 aspect ratio (width:height) so the artwork
  // looks identical on every screen size; the height is derived from the card
  // width rather than hard-coded. Design banners at 2:1.
  static const double _viewportFraction = 0.9;
  static const double _cardHPadding = 6; // must match _BannerCard's padding
  static const double _bannerAspectRatio = 2 / 1;

  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
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
        // Each card occupies [viewportFraction] of the width (minus its inner
        // padding); the height follows the fixed 2:1 ratio.
        final cardWidth =
            constraints.maxWidth * _viewportFraction - _cardHPadding * 2;
        final height = cardWidth / _bannerAspectRatio;
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
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

/// One of the two donation entry points (most-needed pool / a chosen mosque),
/// rendered as a clean full-width card: a tinted icon chip, a title with a
/// short description, and a trailing chevron. Stacked vertically so each path
/// has room to read clearly.
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
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.border, width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.primaryTint,
                    borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

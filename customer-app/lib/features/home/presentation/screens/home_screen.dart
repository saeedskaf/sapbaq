import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/banners/data/banners_repository.dart';
import 'package:sapbaq/features/banners/data/models/banner.dart';
import 'package:sapbaq/features/banners/presentation/banner_link.dart';
import 'package:sapbaq/features/banners/presentation/bloc/banners_cubit.dart';
import 'package:sapbaq/features/home/presentation/widgets/destination_bar.dart';
import 'package:sapbaq/features/home/presentation/widgets/home_store.dart';
import 'package:sapbaq/features/home/presentation/widgets/mosque_needs_strip.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The storefront (Home tab): greeting header, the persistent destination bar
/// («أهدِ إلى: … ▾» — the "deliver to" pattern), banner carousel, a compact
/// Mosque-Needs marketplace strip with live counts, then the product catalogue
/// itself (category chips + grid) — one scrolling page, shop-first.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _hPad = EdgeInsets.symmetric(horizontal: 20);

  // Self-loading storefront sections are refreshed through their public state.
  final _storeKey = GlobalKey<HomeStoreState>();
  final _stripKey = GlobalKey<MosqueNeedsStripState>();

  // Owned here (rather than via BlocProvider.create) so pull-to-refresh can
  // trigger a reload directly.
  late final BannersCubit _bannersCubit;

  @override
  void initState() {
    super.initState();
    _bannersCubit = BannersCubit(context.read<BannersRepository>())..load();
  }

  @override
  void dispose() {
    _bannersCubit.close();
    super.dispose();
  }

  /// Pull-to-refresh: reload banners, the Mosque-Needs counts, and the store
  /// shelves in parallel; the indicator stays until all three settle.
  Future<void> _refresh() async {
    await Future.wait([
      _bannersCubit.load(),
      _stripKey.currentState?.reload() ?? Future<void>.value(),
      _storeKey.currentState?.reload() ?? Future<void>.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.colors.background;
    return BlocProvider.value(
      value: _bannersCubit,
      child: Scaffold(
        // iOS reveals the scaffold background when the list bounces past an
        // edge, so tinting it with the header's top colour makes a
        // pull-to-refresh a seamless continuation of the header. The page
        // content rides on its own opaque [bg] so the tint never leaks while
        // scrolling, and the custom physics clamps the bottom edge so the tint
        // only ever shows at the top — the bottom stays on the page background.
        backgroundColor: _topWash(context),
        // No SafeArea: the wash paints under the status bar and the whole
        // page scrolls as one piece (the top zone pads itself past the
        // status-bar inset).
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: context.colors.primary,
          backgroundColor: context.colors.surface,
          edgeOffset: MediaQuery.paddingOf(context).top,
          child: CustomScrollView(
            physics: const _TopOnlyBounceScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _TopZone(onBannerTap: (b) => openBannerLink(context, b)),
              ),
              // Everything below the wash rides on an opaque page background,
              // so scrolling never reveals the tinted scaffold behind it —
              // only a top overscroll does.
              DecoratedSliver(
                decoration: BoxDecoration(color: bg),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: MosqueNeedsStrip(key: _stripKey),
                      ),
                    ),
                    HomeStore(key: _storeKey),
                    SliverToBoxAdapter(
                      child: SizedBox(height: floatingNavBarClearance(context)),
                    ),
                    // Keeps the opaque page filling the viewport when the
                    // catalogue is short, so the tinted scaffold only ever
                    // shows in an actual top overscroll (never below content).
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delegates to the platform's scroll physics but clamps the trailing (bottom)
/// edge, so a bottom overscroll can never bounce past the content and reveal
/// the tinted scaffold behind it. The leading (top) edge is left untouched, so
/// on iOS it still bounces for pull-to-refresh; on Android everything clamps as
/// usual.
class _TopOnlyBounceScrollPhysics extends ScrollPhysics {
  const _TopOnlyBounceScrollPhysics({super.parent});

  @override
  _TopOnlyBounceScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _TopOnlyBounceScrollPhysics(parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Mirror ClampingScrollPhysics for the trailing edge only; defer the
    // leading edge (and the in-range case) to the platform parent.
    if (position.maxScrollExtent <= position.pixels &&
        position.pixels < value) {
      return value - position.pixels;
    }
    if (position.maxScrollExtent < value &&
        position.maxScrollExtent > position.pixels) {
      return value - position.maxScrollExtent;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

/// The colour at the very top of the storefront. Once a mint wash; now simply
/// the page background — atmosphere washes are gone from the system, the mint
/// appears only as bounded objects. Kept as a function so [_TopZone] and the
/// scaffold stay pinned to the same value during pull-to-refresh.
Color _topWash(BuildContext context) => context.colors.background;

/// Header + banner carousel over a soft brand-tint wash that fades into the
/// scaffold background. Lives inside the scroll view so it moves with the
/// content, and pads itself below the status bar. The tint is theme-aware.
class _TopZone extends StatelessWidget {
  final ValueChanged<PromoBanner> onBannerTap;
  const _TopZone({required this.onBannerTap});

  @override
  Widget build(BuildContext context) {
    // Opaque so the header owns its pixels (the same wash as before, but not
    // dependent on the scaffold showing through): the solid top tint fades
    // down into the page background.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_topWash(context), context.colors.background],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12),
        child: Column(
          children: [
            const Padding(
              padding: _HomeScreenState._hPad,
              child: _HomeHeader(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: DestinationBar(),
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
            const _ProfileAvatarButton(),
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
    final unread = context.watch<NotificationsBadgeCubit>().state;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
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
        ),
        if (unread > 0)
          PositionedDirectional(
            top: 6,
            end: 6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ColorsCustom.error,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: context.colors.surface, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: ColorsCustom.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Profile entry point in the Home top corner (relocated from the bottom dock).
/// A brand-primary disc with a person icon; opens the profile as a pushed
/// full-screen route. Auto-positions by text direction.
class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton();

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
              child: const Icon(
                Icons.person_outline_rounded,
                color: ColorsCustom.textOnPrimary,
                size: 24,
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
              width:
                  constraints.maxWidth * _bannerViewportFraction -
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
                      onTap: banner.isTappable
                          ? () => widget.onTap(banner)
                          : null,
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
          color: ColorsCustom.scrim,
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
                      ? ColorsCustom.white
                      : ColorsCustom.glassEdge,
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

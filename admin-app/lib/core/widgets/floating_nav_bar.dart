import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// Bottom space the floating nav bar occupies (height + gap + safe-area), plus
/// any extra reserved by an ancestor [FloatingBottomInset] (e.g. the cart bar).
/// Add this as bottom padding to scrollable tab content (and to any in-tab
/// bottom bar) so nothing is hidden behind the floating bar.
double floatingNavBarClearance(BuildContext context) =>
    92 + FloatingBottomInset.of(context) + MediaQuery.of(context).padding.bottom;

/// Lets the shell reserve extra bottom clearance for transient bars stacked
/// above the nav bar (the floating cart bar). Page content reads it through
/// [floatingNavBarClearance], so the reservation updates reactively when the
/// shell rebuilds (e.g. the cart goes from empty to non-empty).
class FloatingBottomInset extends InheritedWidget {
  final double extraInset;

  const FloatingBottomInset({
    super.key,
    required this.extraInset,
    required super.child,
  });

  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FloatingBottomInset>()
          ?.extraInset ??
      0;

  @override
  bool updateShouldNotify(FloatingBottomInset oldWidget) =>
      oldWidget.extraInset != extraInset;
}

/// A premium, floating, frosted-glass (glassmorphism) bottom navigation bar
/// with a wide capsule indicator that slides between items.
///
/// - Overlays the page (use `Scaffold(extendBody: true)`) so content blurs
///   through it as you scroll.
/// - RTL-aware (the indicator mirrors automatically) and SafeArea-aware (sits
///   just above the iOS home indicator).
///
/// Tuning (all constructor params):
/// - **Colors:** [background], [activeColor], [inactiveColor], [indicatorColor],
///   [borderColor].
/// - **Transparency:** alpha of [background] (default `surface @ 0.60`) — lower
///   to reveal more content behind; and [indicatorColor] (default `primary @
///   0.16`).
/// - **Blur:** [blur] (default `24`).
/// - **Capsule size:** [indicatorVerticalInset] / [indicatorHorizontalInset]
///   (smaller = larger/wider capsule).
/// - **Motion:** [duration] (default `340ms`) + [curve].
/// - **Shape/size:** [height], [borderRadius], [margin], [bottomGap].
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  final double height;
  final double blur;
  final double borderRadius;
  final EdgeInsets margin;
  final double bottomGap;
  final double indicatorVerticalInset;
  final double indicatorHorizontalInset;
  final Duration duration;
  final Curve curve;
  final Color? background;
  final Color? indicatorColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? borderColor;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.height = 68,
    this.blur = 24,
    this.borderRadius = 30,
    this.margin = const EdgeInsets.symmetric(horizontal: 18),
    this.bottomGap = 12,
    this.indicatorVerticalInset = 8,
    this.indicatorHorizontalInset = 6,
    this.duration = const Duration(milliseconds: 340),
    this.curve = Curves.easeOutCubic,
    this.background,
    this.indicatorColor,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? ColorsCustom.surface.withValues(alpha: 0.60);
    final indicator =
        indicatorColor ?? ColorsCustom.brandMint.withValues(alpha: 0.35);
    final active = activeColor ?? ColorsCustom.primary;
    final inactive = inactiveColor ?? ColorsCustom.textHint;
    final border = borderColor ?? Colors.white.withValues(alpha: 0.55);

    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: margin.left,
        right: margin.right,
        // Sit just above the home indicator — the safe-area inset already
        // provides the spacing; only fall back to bottomGap when there's none.
        bottom: bottomSafe > bottomGap ? bottomSafe : bottomGap,
      ),
      child: DecoratedBox(
        // Soft shadow lives outside the clip so it isn't clipped away.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: border, width: 1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => _content(
                  context,
                  itemWidth: constraints.maxWidth / items.length,
                  indicator: indicator,
                  active: active,
                  inactive: inactive,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context, {
    required double itemWidth,
    required Color indicator,
    required Color active,
    required Color inactive,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Mirror the index in RTL so the indicator tracks the visual slot.
    final visualIndex = isRtl ? (items.length - 1 - currentIndex) : currentIndex;
    final pillRadius = (height - indicatorVerticalInset * 2) / 2;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: duration,
          curve: curve,
          top: indicatorVerticalInset,
          bottom: indicatorVerticalInset,
          left: visualIndex * itemWidth + indicatorHorizontalInset,
          width: itemWidth - indicatorHorizontalInset * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: indicator,
              borderRadius: BorderRadius.circular(pillRadius),
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavItemView(
                  item: items[i],
                  selected: i == currentIndex,
                  activeColor: active,
                  inactiveColor: inactive,
                  duration: duration,
                  curve: curve,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class _NavItemView extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Duration duration;
  final Curve curve;
  final VoidCallback onTap;

  const _NavItemView({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.duration,
    required this.curve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.12 : 1.0,
            duration: duration,
            curve: curve,
            child: _icon(color),
          ),
          const SizedBox(height: 4),
          TextCustom(
            text: item.label,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _icon(Color color) {
    // Crossfade between the outlined and filled icon on selection.
    final iconData = selected ? item.activeIcon : item.icon;
    Widget icon = AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Icon(iconData, key: ValueKey(iconData), size: 24, color: color),
    );

    if (item.badgeCount > 0) {
      icon = Badge(
        backgroundColor: ColorsCustom.error,
        textColor: ColorsCustom.textOnPrimary,
        label: Text(item.badgeCount > 99 ? '99+' : '${item.badgeCount}'),
        child: icon,
      );
    }
    return icon;
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';

/// The brand surface: a flat [ColorsCustom.ink] panel that the white/mint logo
/// lockup sits on.
///
/// Deliberately flat. A mint gradient was tried here and removed: the mint is a
/// mid-light colour, so spread thin across a panel it reads as a smudge rather
/// than as brand (1.73:1 against the light page). The hue earns its keep as a
/// bounded object with dark content on it — see [ColorsCustom.brandMint] —
/// not as atmosphere. On this panel the logo itself is the mint.
///
/// The ground is ink in **both** themes, which is what lets every foreground on
/// it stay white regardless of the active mode.
class BrandBackdrop extends StatelessWidget {
  /// Content drawn over the panel. Must be white or [ColorsCustom.brandMint] —
  /// never a neutral that assumes a light ground.
  final Widget child;

  /// Rounds the panel. The auth header rounds only its bottom corners.
  final BorderRadius? borderRadius;

  const BrandBackdrop({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorsCustom.ink,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

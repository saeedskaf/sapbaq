import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';

/// The strip a modal sheet opens with: the centred drag handle plus a small
/// circular ✕ on the trailing side.
///
/// The handle alone only reads as "swipe me away" to someone who already knows
/// the gesture, and on a tall sheet the swipe competes with the content's own
/// scrolling — the ✕ is the unmistakable way out.
class SheetHandleBar extends StatelessWidget {
  /// Drops the ✕ for sheets that must be answered rather than dismissed.
  final bool showClose;

  /// What ✕ does; pops the sheet when left null.
  final VoidCallback? onClose;

  const SheetHandleBar({super.key, this.showClose = true, this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (showClose)
            PositionedDirectional(
              end: 10,
              top: 8,
              child: SheetCloseButton(onTap: onClose),
            ),
        ],
      ),
    );
  }
}

/// Small circular dismiss control for a sheet.
///
/// Public because it is also used on its own, without a drag handle beside it:
/// a sheet that forbids dragging has no business drawing a grabber, but it
/// still needs the one control that gets a customer out.
class SheetCloseButton extends StatelessWidget {
  final VoidCallback? onTap;

  /// Diameter. The default sits beside a drag handle; a lone corner button is
  /// given a little more, since nothing else near it says "this is the way out".
  final double size;

  const SheetCloseButton({super.key, this.onTap, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceVariant,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).pop(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.close_rounded,
            size: size * 0.6,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

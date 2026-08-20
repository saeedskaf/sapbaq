import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

class ShowMessage {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? foregroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    // A message is neither an action nor a state, so the default banner is
    // neutral — and it takes its colours from the app's own SnackBar theme so
    // the overlay toast below and a real SnackBar can never drift apart. The
    // saturated status fills (success/error) pass their own white foreground.
    final snack = Theme.of(context).snackBarTheme;
    final bg = backgroundColor ?? snack.backgroundColor!;
    final fg =
        foregroundColor ??
        (backgroundColor == null
            ? snack.contentTextStyle!.color!
            : ColorsCustom.textOnPrimary);
    final banner = _Banner(message: message, icon: icon, foreground: fg);

    // A SnackBar is painted *inside* the page's Scaffold, but a bottom sheet or
    // dialog is a route stacked *above* it — so a message posted from inside
    // one would be hidden behind it. Render those as a root-overlay toast,
    // which sits above every route. Everything else keeps the SnackBar.
    if (_isBelowAModal(context)) {
      _Toast.show(context, banner: banner, background: bg, duration: duration);
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: banner,
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Whether [context] sits under something that would cover a SnackBar: it
  /// belongs to a popup route (sheet/dialog), or to a route another one has
  /// been pushed over.
  static bool _isBelowAModal(BuildContext context) {
    final route = ModalRoute.of(context);
    return route is PopupRoute || (route != null && !route.isCurrent);
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: ColorsCustom.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: ColorsCustom.error,
      icon: Icons.error_outline_rounded,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message,
      // No explicit colours — an info banner is the plain neutral default.
      icon: Icons.info_outline_rounded,
    );
  }
}

/// The banner's contents — identical whether it rides a SnackBar or a toast.
class _Banner extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color foreground;

  const _Banner({required this.message, this.icon, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: TextCustom(
            text: message,
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A SnackBar look-alike rendered in the root overlay, so it stays visible over
/// bottom sheets and dialogs. One at a time: a new message replaces the old.
class _Toast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required Widget banner,
    required Color background,
    required Duration duration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _dismiss();
    final entry = OverlayEntry(
      builder: (overlayContext) =>
          _ToastHost(background: background, onTap: _dismiss, child: banner),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _ToastHost extends StatelessWidget {
  final Widget child;
  final Color background;
  final VoidCallback onTap;

  const _ToastHost({
    required this.child,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      left: 16,
      right: 16,
      // Clear the keyboard and the home indicator, exactly like the floating
      // SnackBar this stands in for.
      bottom: media.viewInsets.bottom + media.padding.bottom + 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        builder: (_, t, banner) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: banner,
          ),
        ),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

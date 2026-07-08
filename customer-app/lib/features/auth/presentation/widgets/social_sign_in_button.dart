import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

/// Branded sign-in buttons for Google and Apple.
///
/// These deliberately do NOT use the app's [ButtonCustom] styling: Google's and
/// Apple's sign-in guidelines mandate specific colors, logos, and light/dark
/// treatments, and matching them is what makes the buttons feel trustworthy —
/// the same look users see across global apps. Only the corner radius (16) is
/// borrowed from the app so the buttons still sit naturally in the login form.
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton._({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.logo,
  });

  /// Google button: white with a hairline border in light mode, near-black in
  /// dark mode. The multicolor "G" mark is unchanged in both — per Google's
  /// branding spec the logo is never recolored.
  factory SocialSignInButton.google({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return SocialSignInButton._(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      background: isDark ? const Color(0xFF131314) : Colors.white,
      foreground: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
      borderColor: isDark ? const Color(0xFF8E918F) : const Color(0xFF747775),
      logo: const _GoogleLogo(),
    );
  }

  /// Apple button: black-on-light, white-on-dark, following Apple's Human
  /// Interface Guidelines so it always contrasts with the page background.
  factory SocialSignInButton.apple({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final fg = isDark ? Colors.black : Colors.white;
    return SocialSignInButton._(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      background: isDark ? Colors.white : Colors.black,
      foreground: fg,
      borderColor: isDark ? Colors.white : Colors.black,
      logo: Icon(Icons.apple, size: 22, color: fg),
    );
  }

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final Widget logo;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Opacity(
          opacity: isDisabled && !isLoading ? 0.6 : 1,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: Center(child: logo)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: TextCustom(
                        text: label,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The official multicolor Google "G" mark, drawn from the canonical inline SVG
/// so it stays crisp at any density and identical in light and dark themes.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  static const String _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
      '<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>'
      '<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>'
      '<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>'
      '<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 20, height: 20);
  }
}

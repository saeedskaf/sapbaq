import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sapbaq_admin/core/constants/app_assets.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// Shared layout for auth screens: a full-width **green header** with rounded
/// bottom corners holding the brand logo (the green logo card blends into it),
/// then a title/subtitle and the form [children].
class AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  /// The brand mint — matches the admin logo card so it blends into the header.
  static const Color _headerGreen = Color(0xFF87CDAA);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-width green header behind the logo, with rounded bottom
            // corners — the green logo card blends in. Dark status-bar icons and
            // back button for contrast on the mint fill.
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _headerGreen,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 48,
                          child: canPop
                              ? const Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: BackButton(color: Colors.black),
                                )
                              : null,
                        ),
                        Image.asset(AppAssets.logoFull, width: 220),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextCustom.heading(text: title, fontSize: 26),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    TextCustom.body(
                      text: subtitle!,
                      color: ColorsCustom.textSecondary,
                      fontSize: 15,
                    ),
                  ],
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

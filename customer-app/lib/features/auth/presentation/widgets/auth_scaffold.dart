import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sapbaq/core/constants/app_assets.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/brand_backdrop.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';

/// Shared layout for auth screens: a full-width **black header** with rounded
/// bottom corners holding the brand logo (the black logo card blends into it),
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

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-width flat ink header behind the logo, with rounded bottom
            // corners — keeps the white/mint lockup legible in any theme. Flat
            // on purpose: the logo is the only brand mark this panel needs.
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: BrandBackdrop(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
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
                                  child: BackButton(color: ColorsCustom.white),
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
                      color: context.colors.textSecondary,
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

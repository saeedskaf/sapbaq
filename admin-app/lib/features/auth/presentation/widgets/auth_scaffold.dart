import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sapbaq_admin/core/constants/app_assets.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// Shared layout for auth screens: a full-width **ink header** with rounded
/// bottom corners holding the brand logo (the white/mint-on-black lockup), then
/// a title/subtitle and the form [children]. Matches the customer app so both
/// apps open on the same brand moment.
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
            // Full-width ink header behind the logo, with rounded bottom
            // corners — keeps the white/mint-on-black lockup legible in any
            // theme. Light status-bar icons + back button for contrast.
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ColorsCustom.brandMint,
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
                                  child: BackButton(color: Colors.white),
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

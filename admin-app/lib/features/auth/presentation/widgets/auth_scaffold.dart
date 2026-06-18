import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/constants/app_assets.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// Shared layout for auth screens: the brand mark, a title/subtitle, then the
/// form [children].
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset(AppAssets.logoMarkOnLight, height: 64)),
              const SizedBox(height: 28),
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
      ),
    );
  }
}

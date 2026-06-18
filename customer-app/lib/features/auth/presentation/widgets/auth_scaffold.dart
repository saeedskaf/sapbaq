import 'package:flutter/material.dart';
import 'package:sapbaq/core/constants/app_assets.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

/// Shared layout for auth screens: a back-enabled app bar, the brand mark,
/// a title/subtitle, then the form [children].
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? AppAssets.logoMarkOnDark
                      : AppAssets.logoMarkOnLight,
                  height: 60,
                ),
              ),
              const SizedBox(height: 28),
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
      ),
    );
  }
}

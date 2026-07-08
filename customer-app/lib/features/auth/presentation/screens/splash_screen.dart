import 'package:flutter/material.dart';
import 'package:sapbaq/core/constants/app_assets.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';

/// Shown while the session is being resolved at startup (AuthStatus.unknown).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Solid black with the unified logo (FLUTTER_TASKS items 1 + 16).
      body: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AppAssets.logoFull, width: 220),
              const SizedBox(height: 40),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsCustom.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

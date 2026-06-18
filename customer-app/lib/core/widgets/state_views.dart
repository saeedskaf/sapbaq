import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

/// Centered loading spinner.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(color: context.colors.primary));
}

/// Centered error state with a retry action.
class ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: context.colors.textHint,
            ),
            const SizedBox(height: 16),
            TextCustom.body(
              text: message,
              color: context.colors.textSecondary,
              fontSize: 15,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ButtonCustom.primary(
              text: retryLabel,
              width: 180,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered empty state.
class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.colors.textHint),
            const SizedBox(height: 16),
            TextCustom.body(
              text: message,
              color: context.colors.textSecondary,
              fontSize: 15,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

class LoadingModal {
  static bool _isShowing = false;

  static void show(BuildContext context, {String? message}) {
    if (_isShowing) return;

    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      useRootNavigator: true,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                    strokeWidth: 3,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  TextCustom(
                    text: message,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textPrimary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).then((_) => _isShowing = false);
  }

  static void dismiss(BuildContext context) {
    if (_isShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isShowing = false;
    }
  }

  static bool get isShowing => _isShowing;
}

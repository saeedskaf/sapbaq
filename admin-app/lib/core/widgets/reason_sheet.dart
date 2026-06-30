import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// A bottom sheet that collects a single free-text reason and pops the trimmed
/// string (or null on cancel). Shared by the raise-escalation / reject / cancel
/// flows so they look and behave identically.
class ReasonSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String confirmLabel;
  final Color accent;

  const ReasonSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
    this.accent = ColorsCustom.primary,
  });

  /// Presents the sheet and resolves to the trimmed reason, or null if the user
  /// dismissed it.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String hint,
    required String confirmLabel,
    Color accent = ColorsCustom.primary,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReasonSheet(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        accent: accent,
      ),
    );
  }

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsCustom.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextCustom.subheading(text: widget.title, color: widget.accent),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(hintText: widget.hint),
          ),
          const SizedBox(height: 20),
          ButtonCustom(
            text: widget.confirmLabel,
            color: widget.accent,
            textColor: ColorsCustom.textOnPrimary,
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          ),
          const SizedBox(height: 10),
          ButtonCustom.secondary(
            text: l10n.cancelButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

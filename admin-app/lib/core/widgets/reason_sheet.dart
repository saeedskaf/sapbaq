import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// A bottom sheet that collects a single free-text reason. Shared by the
/// raise-escalation / reject / cancel / complete flows so they look and behave
/// identically.
///
/// Resolves to the trimmed text, or null when the user cancels or dismisses the
/// sheet. Null always means "aborted" — when [required] (the default) the
/// confirm button keeps the sheet open and shows an inline error while the
/// field is empty, so confirming can never resolve to an empty string. Only a
/// sheet built with `required: false` can resolve to `''`, meaning the user
/// deliberately confirmed without giving a reason.
class ReasonSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String confirmLabel;

  /// Whether the field must be filled in before [confirmLabel] will close the
  /// sheet. Only turn this off where the backend accepts a missing reason.
  final bool required;

  /// Inline error shown on an empty required confirm. Defaults to the generic
  /// `fieldRequired` when null; pass a specific message where one exists.
  final String? errorText;

  /// Renders the title and confirm button in the error color, for destructive
  /// flows (reject / cancel / suspend).
  final bool danger;

  const ReasonSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
    this.required = true,
    this.errorText,
    this.danger = false,
  });

  /// Presents the sheet. See the class doc for what the result means.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String hint,
    required String confirmLabel,
    bool required = true,
    String? errorText,
    bool danger = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReasonSheet(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        required: required,
        errorText: errorText,
        danger: danger,
      ),
    );
  }

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (widget.required && value.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = widget.danger ? context.colors.danger : context.colors.primary;
    final media = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        media.viewInsets.bottom + media.padding.bottom + 20,
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
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextCustom.subheading(text: widget.title, color: accent),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: _showError
                  ? (widget.errorText ?? l10n.fieldRequired)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.danger)
            ButtonCustom(
              text: widget.confirmLabel,
              color: ColorsCustom.error,
              textColor: ColorsCustom.textOnPrimary,
              onPressed: _confirm,
            )
          else
            ButtonCustom.primary(
              text: widget.confirmLabel,
              onPressed: _confirm,
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

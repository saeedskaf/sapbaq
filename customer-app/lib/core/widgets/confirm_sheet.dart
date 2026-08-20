import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

/// The app's single "are you sure?" surface — a bottom sheet, not a centered
/// dialog, so it sits where the thumb is, lifts above the keyboard when it
/// carries a text field, and matches the review / product / destination sheets
/// the rest of the app already uses. It mirrors `ReasonSheet` in the staff app.
///
/// Use [ask] for a plain confirmation and [askWithReason] when the action also
/// collects an optional free-text reason. Both resolve the same way: dismissing
/// the sheet (barrier tap, back gesture, or the cancel button) means "aborted",
/// so a null result is never a confirmation.
class ConfirmSheet extends StatefulWidget {
  final String title;

  /// One supporting line under the title — what actually happens if they
  /// confirm. Omit only when the title already says everything.
  final String? body;

  final String confirmLabel;
  final String cancelLabel;

  /// Rendered in a tinted circle above the title.
  final IconData icon;

  /// Destructive actions (cancel, delete, remove) paint the icon and the
  /// confirm button in the error color; everything else uses the brand green.
  final bool danger;

  /// Swaps which button carries the visual weight: [cancelLabel] becomes the
  /// filled button on top and [confirmLabel] the quiet one below.
  ///
  /// The default puts the emphasis on confirming, which is right when the sheet
  /// asks "shall we go ahead?". It is exactly wrong when the sheet is a *guard*
  /// — "are you sure you want to abandon this?" — because there the safe answer
  /// is to stay, and a filled brand-coloured "leave" button reads as the
  /// recommended one. The payment page is the case in point: a mis-tap there
  /// abandons a charge the gateway may already have taken.
  ///
  /// The return value is unaffected: [confirmLabel] still resolves the sheet as
  /// confirmed no matter where it is drawn.
  final bool invertEmphasis;

  /// When non-null a free-text field is shown under the body, labelled with
  /// this. The reason is always optional — the confirm button never blocks on
  /// an empty field.
  final String? reasonLabel;
  final String? reasonHint;

  const ConfirmSheet({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.body,
    this.icon = Icons.help_outline_rounded,
    this.danger = true,
    this.invertEmphasis = false,
    this.reasonLabel,
    this.reasonHint,
  });

  /// Asks for a plain confirmation. Resolves true only when the user pressed
  /// the confirm button.
  static Future<bool> ask(
    BuildContext context, {
    required String title,
    String? body,
    required String confirmLabel,
    required String cancelLabel,
    IconData icon = Icons.help_outline_rounded,
    bool danger = true,
    bool invertEmphasis = false,
  }) async {
    final result = await _show(
      context,
      ConfirmSheet(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        danger: danger,
        invertEmphasis: invertEmphasis,
      ),
    );
    return result != null;
  }

  /// Asks for a confirmation that also collects an optional reason.
  ///
  /// Returns null when the user backed out, the trimmed reason when they gave
  /// one, and `''` when they confirmed without filling the field.
  static Future<String?> askWithReason(
    BuildContext context, {
    required String title,
    String? body,
    required String reasonLabel,
    String? reasonHint,
    required String confirmLabel,
    required String cancelLabel,
    IconData icon = Icons.help_outline_rounded,
    bool danger = true,
  }) {
    return _show(
      context,
      ConfirmSheet(
        title: title,
        body: body,
        reasonLabel: reasonLabel,
        reasonHint: reasonHint,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        danger: danger,
      ),
    );
  }

  static Future<String?> _show(BuildContext context, ConfirmSheet sheet) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Long copy scrolls inside the sheet instead of pushing it full-screen.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (_) => sheet,
    );
  }

  @override
  State<ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<ConfirmSheet> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.reasonLabel != null) _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _confirm() {
    if (widget.danger) HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_controller?.text.trim() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = widget.danger ? colors.danger : colors.primary;
    final badgeFill = widget.danger
        ? colors.danger.withValues(alpha: 0.12)
        : colors.surfaceVariant;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 28, color: accent),
                ),
              ),
              const SizedBox(height: 16),
              TextCustom.subheading(
                text: widget.title,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              if (widget.body != null) ...[
                const SizedBox(height: 8),
                TextCustom.body(
                  text: widget.body!,
                  fontSize: 14,
                  color: colors.textSecondary,
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.reasonLabel != null) ...[
                const SizedBox(height: 20),
                FormFieldCustom(
                  controller: _controller,
                  label: widget.reasonLabel,
                  hintText: widget.reasonHint,
                  isRequired: false,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ],
              const SizedBox(height: 24),
              if (widget.invertEmphasis) ...[
                // Staying is the safe answer, so it gets the filled button and
                // the thumb-reachable slot; leaving stays available but quiet.
                ButtonCustom.primary(
                  text: widget.cancelLabel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 10),
                ButtonCustom.secondary(
                  text: widget.confirmLabel,
                  onPressed: _confirm,
                ),
              ] else ...[
                ButtonCustom(
                  text: widget.confirmLabel,
                  color: widget.danger ? ColorsCustom.error : null,
                  textColor: widget.danger ? ColorsCustom.textOnPrimary : null,
                  onPressed: _confirm,
                ),
                const SizedBox(height: 10),
                ButtonCustom.secondary(
                  text: widget.cancelLabel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

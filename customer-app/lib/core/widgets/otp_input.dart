import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';

/// The number of digits in a verification code (SMS OTP).
const int kOtpLength = 6;

/// A 6-cell verification-code entry. Renders the typed digits over a real
/// (transparent) text field so the OS keyboard, paste, and SMS autofill all
/// work; taps anywhere focus the field. Direction-neutral (always fills
/// left→right). When all six digits are entered it fires [onCompleted] once —
/// callers use that to dismiss the keyboard and advance.
class OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpInput({
    super.key,
    required this.controller,
    this.autofocus = true,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(() => setState(() {}));
  }

  void _onChanged() {
    setState(() {});
    final text = widget.controller.text;
    widget.onChanged?.call(text);
    if (text.length == kOtpLength) widget.onCompleted?.call(text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = _focusNode.hasFocus;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(kOtpLength, (i) {
                final digit = i < text.length ? text[i] : '';
                final active =
                    widget.enabled &&
                    focused &&
                    i == text.length.clamp(0, kOtpLength - 1) &&
                    text.length < kOtpLength;
                final borderColor = widget.hasError
                    ? context.colors.danger
                    : active
                    ? context.colors.primary
                    : context.colors.border;
                return Container(
                  width: 46,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: active || widget.hasError ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    digit,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                );
              }),
            ),
          ),
          // The real field, invisible but hit-testable, drives the keyboard.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                showCursor: false,
                enableInteractiveSelection: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(kOtpLength),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

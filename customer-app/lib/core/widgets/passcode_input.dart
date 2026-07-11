import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/passcode_rules.dart';

/// A 4-cell passcode entry. Renders filled dots over a real (transparent) text
/// field so the OS keyboard, paste, and autofill-from-SMS all work; taps
/// anywhere focus the field. Direction-neutral (always fills left→right).
class PasscodeInput extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const PasscodeInput({
    super.key,
    required this.controller,
    this.autofocus = true,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<PasscodeInput> createState() => _PasscodeInputState();
}

class _PasscodeInputState extends State<PasscodeInput> {
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
    if (text.length == kPasscodeLength) widget.onCompleted?.call(text);
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
              children: List.generate(kPasscodeLength, (i) {
                final filled = i < text.length;
                final active = widget.enabled &&
                    focused &&
                    i == text.length.clamp(0, kPasscodeLength - 1) &&
                    text.length < kPasscodeLength;
                final borderColor = widget.hasError
                    ? ColorsCustom.error
                    : active
                        ? context.colors.primary
                        : context.colors.border;
                return Container(
                  width: 56,
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: active || widget.hasError ? 1.5 : 1,
                    ),
                  ),
                  child: filled
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: context.colors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(kPasscodeLength),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

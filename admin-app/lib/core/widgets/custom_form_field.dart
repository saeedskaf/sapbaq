// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:sapbaq_admin/core/constants/app_constants.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

const Duration _kAnim = Duration(milliseconds: 160);
const double _kRadius = 14;

/// A field label rendered above the input (clean, RTL-friendly), with an
/// optional required asterisk and an optional trailing widget (e.g. a small
/// icon that hints at the field's purpose, like a WhatsApp glyph).
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final Widget? trailing;
  const _FieldLabel({
    required this.text,
    required this.isRequired,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextCustom(
            text: text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorsCustom.textPrimary,
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            const TextCustom(
              text: '*',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ColorsCustom.error,
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Inline error row shown below an input (icon + message).
class _FieldError extends StatelessWidget {
  final String message;
  const _FieldError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 15,
            color: ColorsCustom.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextCustom(
              text: message,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: ColorsCustom.error,
            ),
          ),
        ],
      ),
    );
  }
}

class FormFieldCustom extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? label;
  final String? prefixText;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const FormFieldCustom({
    super.key,
    this.controller,
    this.hintText,
    this.label,
    this.prefixText,
    this.isPassword = false,
    this.isRequired = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  State<FormFieldCustom> createState() => _FormFieldCustomState();
}

class _FormFieldCustomState extends State<FormFieldCustom> {
  bool _obscureText = true;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Latin/numeric content should read left-to-right even in an RTL layout.
  bool get _forceLtr =>
      widget.isPassword ||
      widget.keyboardType == TextInputType.number ||
      widget.keyboardType == TextInputType.phone ||
      widget.keyboardType == TextInputType.emailAddress ||
      widget.keyboardType == TextInputType.url;

  bool _isArabic(String? text) {
    if (text == null || text.isEmpty) return false;
    return text.contains(RegExp(r'[؀-ۿ]'));
  }

  TextStyle _textStyle({
    required double fontSize,
    Color? color,
    FontWeight? weight,
  }) {
    final isArabic = _isArabic(widget.hintText ?? widget.label ?? '');
    final font = isArabic ? GoogleFonts.tajawal : GoogleFonts.poppins;
    return font(
      fontSize: fontSize,
      fontWeight: weight ?? FontWeight.w500,
      color: color ?? ColorsCustom.textPrimary,
      height: 1.5,
      letterSpacing: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = _isFocused
        ? ColorsCustom.primary
        : ColorsCustom.textHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          _FieldLabel(text: widget.label!, isRequired: widget.isRequired),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textAlignVertical: TextAlignVertical.center,
          textDirection: _forceLtr ? TextDirection.ltr : null,
          textAlign: _forceLtr ? TextAlign.left : TextAlign.start,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          cursorColor: ColorsCustom.primary,
          style: _textStyle(
            fontSize: 15,
            color: widget.enabled
                ? ColorsCustom.textPrimary
                : ColorsCustom.textHint,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: !widget.enabled
                ? ColorsCustom.surfaceVariant
                : (_isFocused ? ColorsCustom.inputFocusFill : ColorsCustom.surface),
            hintText: widget.hintText,
            hintStyle: _textStyle(
              fontSize: 15,
              color: ColorsCustom.textHint,
              weight: FontWeight.w400,
            ),
            prefixText: widget.prefixText,
            prefixStyle: _textStyle(
              fontSize: 15,
              color: ColorsCustom.textSecondary,
            ),
            prefixIcon: widget.prefixIcon == null
                ? null
                : IconTheme(
                    data: IconThemeData(color: iconColor, size: 22),
                    child: widget.prefixIcon!,
                  ),
            suffixIcon: _buildSuffixIcon(iconColor),
            isDense: false,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _border(ColorsCustom.border),
            enabledBorder: _border(ColorsCustom.border),
            focusedBorder: _border(ColorsCustom.primary, width: 1.5),
            errorBorder: _border(ColorsCustom.error),
            focusedErrorBorder: _border(ColorsCustom.error, width: 1.5),
            disabledBorder: _border(ColorsCustom.border, width: 0.5),
            errorStyle: _textStyle(
              fontSize: 13,
              color: ColorsCustom.error,
              weight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget? _buildSuffixIcon(Color iconColor) {
    if (widget.isPassword) {
      return IconButton(
        splashRadius: 20,
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: iconColor,
          size: 22,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return widget.suffixIcon;
  }
}

class PhoneFieldCustom extends StatefulWidget {
  final String label;
  final bool isRequired;
  final String initialCountryCode;
  final String hintText;
  final ValueChanged<PhoneNumber>? onChanged;
  final String? errorText;
  final String? initialValue;

  /// Optional widget rendered to the right of the label — e.g. a small
  /// WhatsApp glyph that hints at the channel this number will be used for.
  final Widget? labelTrailing;

  const PhoneFieldCustom({
    super.key,
    required this.label,
    this.isRequired = true,
    this.initialCountryCode = AppConstants.defaultCountryCode,
    this.hintText = 'XXXX XXXX',
    this.onChanged,
    this.errorText,
    this.initialValue,
    this.labelTrailing,
  });

  @override
  State<PhoneFieldCustom> createState() => _PhoneFieldCustomState();
}

class _PhoneFieldCustomState extends State<PhoneFieldCustom> {
  bool _isFocused = false;

  TextStyle _textStyle({
    double fontSize = 15,
    Color? color,
    FontWeight? weight,
  }) {
    return GoogleFonts.tajawal(
      fontSize: fontSize,
      fontWeight: weight ?? FontWeight.w500,
      color: color ?? ColorsCustom.textPrimary,
      height: 1.5,
      letterSpacing: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasError = widget.errorText != null;
    final Color borderColor = hasError
        ? ColorsCustom.error
        : _isFocused
        ? ColorsCustom.primary
        : ColorsCustom.border;
    final double borderWidth = hasError || _isFocused ? 1.5 : 1.0;
    final Color fillColor = hasError
        ? ColorsCustom.surface
        : (_isFocused ? ColorsCustom.inputFocusFill : ColorsCustom.surface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          text: widget.label,
          isRequired: widget.isRequired,
          trailing: widget.labelTrailing,
        ),
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: _kAnim,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: IntlPhoneField(
                initialCountryCode: widget.initialCountryCode,
                initialValue: widget.initialValue,
                languageCode: Localizations.localeOf(context).languageCode,
                // Accept any international number — no per-country length rule.
                disableLengthCheck: true,
                autovalidateMode: AutovalidateMode.disabled,
                showCountryFlag: true,
                showDropdownIcon: true,
                dropdownIconPosition: IconPosition.trailing,
                dropdownIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ColorsCustom.textHint,
                  size: 20,
                ),
                style: _textStyle(fontSize: 15),
                dropdownTextStyle: _textStyle(
                  fontSize: 15,
                  color: ColorsCustom.textSecondary,
                ),
                flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 12),
                pickerDialogStyle: PickerDialogStyle(
                  backgroundColor: ColorsCustom.surface,
                  countryNameStyle: _textStyle(
                    fontSize: 15,
                    color: ColorsCustom.textPrimary,
                  ),
                  countryCodeStyle: _textStyle(
                    fontSize: 14,
                    color: ColorsCustom.textSecondary,
                  ),
                  searchFieldCursorColor: ColorsCustom.primary,
                  searchFieldInputDecoration: InputDecoration(
                    hintText: l10n.searchCountry,
                    hintStyle: _textStyle(
                      fontSize: 15,
                      color: ColorsCustom.textHint,
                      weight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: ColorsCustom.textHint,
                      size: 20,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_kRadius),
                      borderSide: const BorderSide(color: ColorsCustom.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_kRadius),
                      borderSide: const BorderSide(
                        color: ColorsCustom.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: _textStyle(
                    fontSize: 15,
                    color: ColorsCustom.textHint,
                    weight: FontWeight.normal,
                  ),
                  filled: false,
                  isDense: false,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
        if (hasError) _FieldError(message: widget.errorText!),
      ],
    );
  }
}

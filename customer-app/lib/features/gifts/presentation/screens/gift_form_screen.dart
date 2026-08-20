import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/form_validators.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Route args for the gift form: which cart the gift attaches to, and the
/// existing gift when editing.
class GiftFormArgs {
  final int cartId;
  final Gift? existing;
  const GiftFormArgs(this.cartId, {this.existing});
}

/// Printed on the card when the donor keeps their name private.
///
/// Deliberately a constant and not a translation: the server composes the card
/// in Arabic for a third party to read, so this must not follow the donor's
/// app language.
const String kAnonymousSenderName = 'فاعل خير';

/// Kuwaiti subscriber numbers are 8 digits; the country code lives in the
/// field's own picker and is never part of this count.
const int _kPhoneDigits = 8;

/// Attach / replace one cart's gift (إهداء): who it's for, the WhatsApp number
/// to notify, and — optionally — the donor's name. The card artwork is chosen
/// server-side from the one approved design, so the donor never picks one
/// (GIFT_SIMPLIFIED_2026-08-04). Pass [existing] to edit.
class GiftFormScreen extends StatefulWidget {
  final int cartId;
  final Gift? existing;

  const GiftFormScreen({super.key, required this.cartId, this.existing});

  @override
  State<GiftFormScreen> createState() => _GiftFormScreenState();
}

class _GiftFormScreenState extends State<GiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dedicatedController = TextEditingController();
  final _senderController = TextEditingController();

  /// Off → gift privately: the card reads «تقديم من فاعل خير».
  bool _showSenderName = true;

  /// What we send (E.164) and what we validate (national digits only).
  String _phone = '';
  String _nationalPhone = '';
  String? _phoneError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _dedicatedController.text = existing.dedicatedToName;
      // A gift saved privately comes back with the placeholder as its sender.
      _showSenderName = existing.senderName != kAnonymousSenderName;
      if (_showSenderName) _senderController.text = existing.senderName;
      _phone = existing.notifyPhone;
      _nationalPhone = _nationalDigits(existing.notifyPhone);
    }
  }

  @override
  void dispose() {
    _dedicatedController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  /// The national part of a stored E.164 number — what the input shows once
  /// the country code is split off, and what the 8-digit rule applies to.
  String _nationalDigits(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    const kuwait = '965';
    return digits.startsWith(kuwait) ? digits.substring(kuwait.length) : digits;
  }

  String? _phoneErrorFor(AppLocalizations l10n) {
    if (_nationalPhone.isEmpty) return l10n.phoneRequired;
    if (_nationalPhone.length != _kPhoneDigits) return l10n.phoneEightDigits;
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.read<CartCubit>();
    setState(() => _phoneError = _phoneErrorFor(l10n));
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || _phoneError != null) return;

    setState(() => _busy = true);
    final ok = await cart.attachGift(
      widget.cartId,
      dedicatedToName: _dedicatedController.text.trim(),
      senderName: _showSenderName
          ? _senderController.text.trim()
          : kAnonymousSenderName,
      notifyPhone: _phone,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ShowMessage.success(context, l10n.giftAdded);
      context.pop();
    } else {
      // The server's message is Arabic and display-ready — show it as-is (e.g.
      // "لا يوجد تصميم كرت إهداء مفعّل", an admin-side problem, not the user's).
      ShowMessage.error(context, cart.state.message ?? l10n.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = FormValidators(context);
    final title = widget.existing != null
        ? l10n.editGiftTitle
        : l10n.giftFormTitle;

    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FormFieldCustom(
              controller: _dedicatedController,
              label: l10n.dedicatedToLabel,
              hintText: l10n.dedicatedToHint,
              validator: validators.requiredValidator,
            ),
            const SizedBox(height: 18),
            PhoneFieldCustom(
              label: l10n.phoneLabel,
              hintText: l10n.whatsappNumberHint,
              initialValue: widget.existing?.notifyPhone,
              errorText: _phoneError,
              // Digits only, capped at the Kuwaiti subscriber length; the
              // country code keeps its own picker.
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_kPhoneDigits),
              ],
              onChanged: (p) {
                _phone = p.completeNumber;
                _nationalPhone = p.number;
                if (_phoneError != null) {
                  setState(() => _phoneError = _phoneErrorFor(l10n));
                }
              },
            ),
            const SizedBox(height: 18),
            _SenderSection(
              showName: _showSenderName,
              controller: _senderController,
              onChanged: (v) => setState(() => _showSenderName = v),
              validator: validators.requiredValidator,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ButtonCustom.primary(
          text: l10n.saveGift,
          isLoading: _busy,
          onPressed: _submit,
        ),
      ),
    );
  }
}

/// «تقديم من» as a switch: on reveals the donor's name field, off gifts
/// privately. The status line spells out what the recipient will read either
/// way, since the donor never sees the finished card.
class _SenderSection extends StatelessWidget {
  final bool showName;
  final TextEditingController controller;
  final ValueChanged<bool> onChanged;
  final FormFieldValidator<String> validator;

  const _SenderSection({
    required this.showName,
    required this.controller,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: l10n.senderNameLabel,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 3),
                    TextCustom(
                      text: showName
                          ? l10n.giftSenderShownHint
                          : l10n.giftSenderPrivateHint,
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ],
                ),
              ),
              Switch(
                value: showName,
                onChanged: onChanged,
                activeThumbColor: context.colors.primary,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: showName
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: FormFieldCustom(
                    controller: controller,
                    hintText: l10n.senderNameHint,
                    validator: validator,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

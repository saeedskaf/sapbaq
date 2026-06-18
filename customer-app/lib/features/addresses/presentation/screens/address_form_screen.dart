import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/addresses/data/addresses_repository.dart';
import 'package:sapbaq/features/addresses/data/models/address.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Add / edit a saved address. `area` is required; everything else is optional.
/// Pops `true` on success so the list can refresh.
class AddressFormScreen extends StatefulWidget {
  final Address? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _area = TextEditingController(text: widget.existing?.area ?? '');
  late final _block = TextEditingController(text: widget.existing?.block ?? '');
  late final _street =
      TextEditingController(text: widget.existing?.street ?? '');
  late final _building =
      TextEditingController(text: widget.existing?.building ?? '');
  late final _details =
      TextEditingController(text: widget.existing?.details ?? '');
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _area.dispose();
    _block.dispose();
    _street.dispose();
    _building.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final repo = context.read<AddressesRepository>();
    setState(() => _busy = true);

    final payload = <String, dynamic>{
      'label': _label.text.trim(),
      'area': _area.text.trim(),
      'block': _block.text.trim(),
      'street': _street.text.trim(),
      'building': _building.text.trim(),
      'details': _details.text.trim(),
      'is_default': _isDefault,
    };

    try {
      if (widget.existing == null) {
        await repo.create(payload);
      } else {
        await repo.update(widget.existing!.id, payload);
      }
      if (!mounted) return;
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ShowMessage.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(
          text: isEdit ? l10n.editAddress : l10n.addAddress,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            FormFieldCustom(
              controller: _label,
              label: l10n.addrLabel,
              hintText: l10n.addrLabelHint,
              isRequired: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              controller: _area,
              label: l10n.addrArea,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.areaRequired : null,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              controller: _block,
              label: l10n.addrBlock,
              isRequired: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              controller: _street,
              label: l10n.addrStreet,
              isRequired: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              controller: _building,
              label: l10n.addrBuilding,
              isRequired: false,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            FormFieldCustom(
              controller: _details,
              label: l10n.addrDetails,
              isRequired: false,
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              activeThumbColor: context.colors.primary,
              title: TextCustom(
                text: l10n.setDefaultAddress,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ButtonCustom.primary(
              text: l10n.saveButton,
              isLoading: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

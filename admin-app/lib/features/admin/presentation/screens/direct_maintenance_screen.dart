import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/equipment_catalog.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/direct_provision_fields.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/maintenance_labels.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Direct maintenance case (manager-direct doc §4.2). The case is born
/// `APPROVED` with no triage step, so the manager fixes the cost path here —
/// the unit picker's `suggested_cost_path` seeds it. It then waits in the claim
/// queue for any team leader in the mosque's governorate.
class DirectMaintenanceScreen extends StatefulWidget {
  const DirectMaintenanceScreen({super.key});

  @override
  State<DirectMaintenanceScreen> createState() =>
      _DirectMaintenanceScreenState();
}

class _DirectMaintenanceScreenState extends State<DirectMaintenanceScreen> {
  static const _issueTypes = [
    'FILTER_CHANGE',
    'NOT_WORKING',
    'LEAKING',
    'OTHER',
  ];
  static const _maxPhotos = 5;

  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final List<String> _photoPaths = [];

  PickedMosque? _mosque;
  List<MaintenanceEquipmentUnit> _units = const [];
  MaintenanceEquipmentUnit? _unit;
  String _issueType = _issueTypes.first;
  String _costPath = MaintenanceEnums.approveCostPaths.first;

  bool _loadingUnits = false;
  bool _busy = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// The units live at the mosque, so picking a mosque reloads them and drops
  /// any previously chosen unit.
  Future<void> _selectMosque(PickedMosque mosque) async {
    setState(() {
      _mosque = mosque;
      _unit = null;
      _units = const [];
      _loadingUnits = true;
    });
    try {
      final units = await context
          .read<AdminRepository>()
          .fetchMaintenanceEquipment(mosque.id);
      if (!mounted) return;
      setState(() {
        _units = units;
        _loadingUnits = false;
        _applyUnit(units.isEmpty ? null : units.first);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingUnits = false);
      ShowMessage.error(context, e.message);
    }
  }

  /// Adopt the unit's suggested cost path as the default — it already accounts
  /// for warranty, which is exactly the call the manager would make.
  void _applyUnit(MaintenanceEquipmentUnit? unit) {
    _unit = unit;
    final suggested = unit?.suggestedCostPath ?? '';
    if (MaintenanceEnums.approveCostPaths.contains(suggested)) {
      _costPath = suggested;
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final unit = _unit;
    if (_mosque == null) {
      ShowMessage.error(context, l10n.dpMosqueRequired);
      return;
    }
    if (unit == null) {
      ShowMessage.error(context, l10n.dpNoUnits);
      return;
    }
    final description = _descriptionController.text.trim();
    if (_issueType == 'OTHER' && description.isEmpty) {
      ShowMessage.error(context, l10n.repIssueOtherNeedsDesc);
      return;
    }
    final price = _priceController.text.trim();
    if (_costPath == 'CUSTOMER_PAID' && (double.tryParse(price) ?? 0) <= 0) {
      ShowMessage.error(context, l10n.mtPriceRequired);
      return;
    }

    setState(() => _busy = true);
    try {
      await context.read<AdminRepository>().createMaintenanceCase(
        equipmentId: unit.id,
        issueType: _issueType,
        costPath: _costPath,
        description: description,
        price: price,
        photoPaths: _photoPaths,
      );
      if (!mounted) return;
      ShowMessage.success(context, l10n.dpCreated);
      context.pop(true);
    } on ApiException catch (e) {
      // e.g. the unit already has an open case.
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.dpMaintenance)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MosqueField(
            value: _mosque,
            enabled: !_busy,
            onChanged: _selectMosque,
          ),
          const SizedBox(height: 20),
          FieldLabel(l10n.dpUnit),
          if (_loadingUnits)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            )
          else if (_mosque == null)
            TextCustom(
              text: l10n.dpMosqueRequired,
              fontSize: 13,
              color: context.colors.textHint,
            )
          else if (_units.isEmpty)
            TextCustom(
              text: l10n.dpNoUnits,
              fontSize: 13,
              color: context.colors.textHint,
            )
          else ...[
            DropdownButtonFormField<MaintenanceEquipmentUnit>(
              initialValue: _unit,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: [
                for (final u in _units)
                  DropdownMenuItem(
                    value: u,
                    child: TextCustom(text: u.label, fontSize: 14, maxLines: 1),
                  ),
              ],
              onChanged: _busy ? null : (u) => setState(() => _applyUnit(u)),
            ),
            if (_unit?.inWarranty == true) ...[
              const SizedBox(height: 8),
              mtChip(l10n.dpUnitInWarranty, ColorsCustom.success),
            ],
          ],
          const SizedBox(height: 20),
          FieldLabel(l10n.repIssueType),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _issueTypes)
                ChoiceChip(
                  label: TextCustom(
                    text: mtIssueLabel(l10n, type),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _issueType == type
                        ? ColorsCustom.textOnPrimary
                        : context.colors.textPrimary,
                  ),
                  selected: _issueType == type,
                  selectedColor: context.colors.primary,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _issueType = type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FormFieldCustom(
            controller: _descriptionController,
            label: l10n.repIssueDescription,
            isRequired: _issueType == 'OTHER',
            maxLines: 3,
            enabled: !_busy,
          ),
          const SizedBox(height: 20),
          FieldLabel(l10n.dpCostPath),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final path in MaintenanceEnums.approveCostPaths)
                ChoiceChip(
                  label: TextCustom(
                    text: mtCostLabel(l10n, path),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _costPath == path
                        ? ColorsCustom.textOnPrimary
                        : context.colors.textPrimary,
                  ),
                  selected: _costPath == path,
                  selectedColor: context.colors.primary,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _costPath = path),
                ),
            ],
          ),
          if (_costPath == 'CUSTOMER_PAID') ...[
            const SizedBox(height: 20),
            FormFieldCustom(
              controller: _priceController,
              label: l10n.mtPriceKwd,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_busy,
            ),
          ],
          const SizedBox(height: 20),
          PhotoPickerField(
            paths: _photoPaths,
            maxPhotos: _maxPhotos,
            enabled: !_busy,
            label: l10n.repPhotos,
            hint: l10n.repPhotosHint,
            onAdd: (path) => setState(() => _photoPaths.add(path)),
            onRemove: (i) => setState(() => _photoPaths.removeAt(i)),
          ),
          const SizedBox(height: 28),
          ButtonCustom.primary(
            text: l10n.dpSubmit,
            isLoading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/equipment_catalog.dart';
import 'package:sapbaq_admin/features/admin/data/models/equipment_option.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/equipment_pick_sheet.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/direct_provision_fields.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Direct equipment request (manager-direct doc §3). Unlike the imam's request
/// — where the model is chosen later, at approval — this one publishes to the
/// marketplace immediately, so the manager fixes the model (and with it the
/// target amount) up front.
class DirectEquipmentScreen extends StatefulWidget {
  const DirectEquipmentScreen({super.key});

  @override
  State<DirectEquipmentScreen> createState() => _DirectEquipmentScreenState();
}

class _DirectEquipmentScreenState extends State<DirectEquipmentScreen> {
  final _noteController = TextEditingController();

  PickedMosque? _mosque;
  List<EquipmentTypeOption> _types = const [];
  EquipmentTypeOption? _type;

  /// The product + combination the manager settled on. Picked in the same sheet
  /// the approval queue uses, so both surfaces behave identically.
  EquipmentPick? _pick;

  bool _loadingTypes = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _loadingTypes = true;
      _error = null;
    });
    try {
      final types = await context.read<AdminRepository>().fetchEquipmentTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _loadingTypes = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingTypes = false;
      });
    }
  }

  /// Models belong to a type, so changing the type invalidates the choice.
  void _selectType(EquipmentTypeOption? type) {
    if (type == null) return;
    // A different family invalidates the pick — its axes belong to the old one.
    setState(() {
      _type = type;
      _pick = null;
    });
  }

  Future<void> _pickEquipment() async {
    final type = _type;
    if (type == null) return;
    final repo = context.read<AdminRepository>();
    final l10n = AppLocalizations.of(context)!;
    final picked = await showEquipmentPickSheet(
      context,
      load: () => repo.fetchEquipmentOptions(type.id),
      title: l10n.dpModel,
    );
    if (picked != null && mounted) setState(() => _pick = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final mosque = _mosque;
    final type = _type;
    final pick = _pick;
    if (mosque == null) {
      ShowMessage.error(context, l10n.dpMosqueRequired);
      return;
    }
    if (type == null || pick == null) {
      ShowMessage.error(context, l10n.dpModelRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AdminRepository>().createEquipmentRequest(
        mosqueId: mosque.id,
        equipmentTypeId: type.id,
        pick: pick,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      ShowMessage.success(context, l10n.dpCreated);
      context.pop(true);
    } on ApiException catch (e) {
      // e.g. an open request for this type already exists at the mosque.
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.dpEquipment)),
      body: _loadingTypes
          ? const LoadingView()
          : _error != null
          ? ErrorView(
              message: _error!,
              retryLabel: l10n.retry,
              onRetry: _loadTypes,
            )
          : _types.isEmpty
          ? EmptyView(message: l10n.dpNoTypes, icon: Icons.kitchen_outlined)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MosqueField(
                  value: _mosque,
                  enabled: !_busy,
                  onChanged: (m) => setState(() => _mosque = m),
                ),
                const SizedBox(height: 20),
                FieldLabel(l10n.dpEquipmentType),
                DropdownButtonFormField<EquipmentTypeOption>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: [
                    for (final t in _types)
                      DropdownMenuItem(
                        value: t,
                        child: TextCustom(
                          text: t.name,
                          fontSize: 14,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  onChanged: _busy ? null : _selectType,
                ),
                const SizedBox(height: 20),
                FieldLabel(l10n.dpModel),
                InkWell(
                  onTap: _busy || _type == null ? null : _pickEquipment,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextCustom(
                            text: _pick?.label ?? l10n.dpModelRequired,
                            fontSize: 14,
                            fontWeight: _pick == null
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: _pick == null
                                ? context.colors.textHint
                                : context.colors.textPrimary,
                            maxLines: 2,
                          ),
                        ),
                        Icon(
                          Icons.chevron_left_rounded,
                          color: context.colors.textHint,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_pick != null && _pick!.price.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TextCustom(
                    text: l10n.dpTargetAmount(_pick!.price),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ],
                const SizedBox(height: 20),
                FormFieldCustom(
                  controller: _noteController,
                  label: l10n.dpNote,
                  isRequired: false,
                  maxLines: 3,
                  enabled: !_busy,
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

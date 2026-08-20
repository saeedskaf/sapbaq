import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';
import 'package:sapbaq_admin/features/rep/data/rep_repository.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// New-equipment request (rep): pick a type (water cooler / fridge / …) + an
/// optional note. One open request per type per mosque — server-enforced.
/// The type catalogue relies on the proposed `GET /rep/equipment-types/`
/// (Gap C): until it ships, the server error shows here with a retry.
class RepEquipmentFormScreen extends StatefulWidget {
  const RepEquipmentFormScreen({super.key});

  @override
  State<RepEquipmentFormScreen> createState() => _RepEquipmentFormScreenState();
}

class _RepEquipmentFormScreenState extends State<RepEquipmentFormScreen> {
  List<RepEquipmentType> _types = const [];
  RepEquipmentType? _type;
  bool _loading = true;
  String? _error;
  final _noteController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await context.read<RepRepository>().equipmentTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _type = types.isEmpty ? null : types.first;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final type = _type;
    if (type == null) return;
    setState(() => _busy = true);
    try {
      await context.read<RepRepository>().requestEquipment(
        equipmentTypeId: type.id,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      ShowMessage.success(context, l10n.repEquipmentRequestSent);
      context.pop();
    } on ApiException catch (e) {
      // e.g. an open request for this type already exists.
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.repRequestEquipment),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, retryLabel: l10n.retry, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextCustom(
                  text: l10n.repEquipmentType,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<RepEquipmentType>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: [
                    for (final type in _types)
                      DropdownMenuItem(
                        value: type,
                        child: TextCustom(
                          text: type.name,
                          fontSize: 14,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 20),
                FormFieldCustom(
                  controller: _noteController,
                  label: l10n.repEquipmentNote,
                  isRequired: false,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ButtonCustom.primary(
                  text: l10n.repReportSubmit,
                  isLoading: _busy,
                  onPressed: _busy || _type == null ? null : _submit,
                ),
              ],
            ),
    );
  }
}

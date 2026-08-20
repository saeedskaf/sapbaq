import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/direct_provision_fields.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Direct water flag (manager-direct doc §2): the manager picks a mosque and
/// the flag is raised already `APPROVED`, published for funding at once. The
/// server rejects a mosque that already has an open flag.
class DirectWaterScreen extends StatefulWidget {
  const DirectWaterScreen({super.key});

  @override
  State<DirectWaterScreen> createState() => _DirectWaterScreenState();
}

class _DirectWaterScreenState extends State<DirectWaterScreen> {
  PickedMosque? _mosque;
  bool _busy = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final mosque = _mosque;
    if (mosque == null) {
      ShowMessage.error(context, l10n.dpMosqueRequired);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.dpWater,
      message: l10n.dpWaterConfirm,
      confirmLabel: l10n.confirmButton,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<AdminRepository>().createWaterFlag(mosque.id);
      if (!mounted) return;
      ShowMessage.success(context, l10n.dpCreated);
      context.pop(true);
    } on ApiException catch (e) {
      // e.g. the mosque already has an active flag, or it's out of scope (403).
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.dpWater)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextCustom(
            text: l10n.dpWaterDesc,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          MosqueField(
            value: _mosque,
            enabled: !_busy,
            onChanged: (m) => setState(() => _mosque = m),
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

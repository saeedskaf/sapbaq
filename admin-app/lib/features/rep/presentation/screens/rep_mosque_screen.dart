import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';
import 'package:sapbaq_admin/features/rep/data/rep_repository.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// «مسجدي» — the representative's home: his mosque + account state, the three
/// report actions (maintenance / water flag / new equipment), and the units
/// registered to his mosque (the same devices he sees daily; spec §10).
class RepMosqueScreen extends StatefulWidget {
  const RepMosqueScreen({super.key});

  @override
  State<RepMosqueScreen> createState() => _RepMosqueScreenState();
}

class _RepMosqueScreenState extends State<RepMosqueScreen> {
  RepProfile? _profile;
  List<RepEquipmentUnit> _units = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<RepRepository>();
      final profile = await repo.me();
      final units = await repo.equipment();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _units = units;
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

  Future<void> _raiseWaterFlag() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.repWaterFlagTitle,
      message: l10n.repWaterFlagConfirm,
      confirmLabel: l10n.confirmButton,
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<RepRepository>().raiseWaterFlag();
      if (mounted) ShowMessage.success(context, l10n.repWaterFlagSent);
    } on ApiException catch (e) {
      // e.g. an active flag already exists — the server message says so.
      if (mounted) ShowMessage.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.repNavMosque)),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, retryLabel: l10n.retry, onRetry: _load)
          : RefreshIndicator(
              color: context.colors.primary,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  floatingNavBarClearance(context),
                ),
                children: [
                  _MosqueHeader(profile: _profile!),
                  const SizedBox(height: 20),
                  TextCustom.subheading(
                    text: l10n.repActionsTitle,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.build_rounded,
                    title: l10n.repReportMaintenance,
                    subtitle: l10n.repReportMaintenanceDesc,
                    onTap: () => context.pushNamed(AppRoutes.repReportFormName),
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.water_drop_rounded,
                    title: l10n.repWaterFlagTitle,
                    subtitle: l10n.repWaterFlagDesc,
                    onTap: _raiseWaterFlag,
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.kitchen_rounded,
                    title: l10n.repRequestEquipment,
                    subtitle: l10n.repRequestEquipmentDesc,
                    onTap: () =>
                        context.pushNamed(AppRoutes.repEquipmentFormName),
                  ),
                  const SizedBox(height: 24),
                  TextCustom.subheading(text: l10n.repUnitsTitle, fontSize: 16),
                  const SizedBox(height: 10),
                  if (_units.isEmpty)
                    TextCustom(
                      text: l10n.repNoUnits,
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    )
                  else
                    for (final unit in _units) _UnitRow(unit: unit),
                ],
              ),
            ),
    );
  }
}

class _MosqueHeader extends StatelessWidget {
  final RepProfile profile;
  const _MosqueHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mosque = profile.mosque;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.mosque_rounded,
              color: context.colors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: mosque?.name ?? l10n.repNavMosque,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (mosque != null && mosque.areaLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  TextCustom(
                    text: mosque.areaLine,
                    fontSize: 12.5,
                    color: context.colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          if (profile.status != RepStatus.active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextCustom(
                text: profile.status == RepStatus.pending
                    ? l10n.repStatusPending
                    : l10n.repStatusDeactivated,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: context.colors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border, width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: context.colors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        text: title,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 2),
                      TextCustom(
                        text: subtitle,
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: context.colors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  final RepEquipmentUnit unit;
  const _UnitRow({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 22,
            color: context.colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unit.typeName.isNotEmpty)
                  TextCustom(
                    text: unit.typeName,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                TextCustom(
                  text: unit.code,
                  fontSize: 12.5,
                  color: context.colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

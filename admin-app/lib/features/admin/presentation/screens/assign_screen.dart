import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/assign_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/mosque_picker_sheet.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/workshop_picker_sheet.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/status_badge.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

class AssignScreen extends StatelessWidget {
  final int orderId;
  const AssignScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AssignCubit(context.read<AdminRepository>(), orderId)..load(),
      child: const _AssignView(),
    );
  }
}

class _AssignView extends StatelessWidget {
  const _AssignView();

  Future<void> _pickWorkshop(BuildContext context, int destinationId) async {
    final cubit = context.read<AssignCubit>();
    final workshop = await showModalBottomSheet<Workshop>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WorkshopPickerSheet(workshops: cubit.state.workshops),
    );
    if (workshop != null) cubit.selectDriver(destinationId, workshop.id);
  }

  Future<void> _pickMosque(BuildContext context, int destinationId) async {
    final cubit = context.read<AssignCubit>();
    final repo = context.read<AdminRepository>();
    final mosque = await showModalBottomSheet<({int id, String name})>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MosquePickerSheet(repository: repo),
    );
    if (mosque != null) {
      cubit.selectMosque(destinationId, mosque.id, mosque.name);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final order = await context.read<AssignCubit>().submit();
    if (order != null && context.mounted) {
      ShowMessage.success(context, l10n.assignSuccess);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.assignTitle)),
      body: BlocConsumer<AssignCubit, AssignState>(
        listenWhen: (a, b) => a.message != b.message && b.message != null,
        listener: (context, state) =>
            ShowMessage.error(context, state.message!),
        builder: (context, state) {
          if (state.status == LoadStatus.loading) return const LoadingView();
          if (state.status == LoadStatus.failure) {
            return ErrorView(
              message: state.message ?? l10n.genericError,
              retryLabel: l10n.retry,
              onRetry: () => context.read<AssignCubit>().load(),
            );
          }
          if (state.workshops.isEmpty) {
            return EmptyView(
              message: l10n.noWorkshops,
              icon: Icons.engineering_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              for (final dest in state.destinations)
                _DestinationAssignCard(
                  destination: dest,
                  choice: state.choices[dest.id],
                  workshops: state.workshops,
                  onPickWorkshop: () => _pickWorkshop(context, dest.id),
                  onPickMosque: () => _pickMosque(context, dest.id),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<AssignCubit, AssignState>(
        builder: (context, state) {
          if (state.status != LoadStatus.success) {
            return const SizedBox.shrink();
          }
          final cubit = context.read<AssignCubit>();
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ButtonCustom.primary(
              text: l10n.confirmAssign,
              isLoading: state.submitting,
              enabled: cubit.canSubmit,
              onPressed: () => _submit(context),
            ),
          );
        },
      ),
    );
  }
}

class _DestinationAssignCard extends StatelessWidget {
  final AdminDestination destination;
  final DestinationChoice? choice;
  final List<Workshop> workshops;
  final VoidCallback onPickWorkshop;
  final VoidCallback onPickMosque;

  const _DestinationAssignCard({
    required this.destination,
    required this.choice,
    required this.workshops,
    required this.onPickWorkshop,
    required this.onPickMosque,
  });

  String? _workshopName() {
    final id = choice?.driverId;
    if (id == null) return null;
    for (final w in workshops) {
      if (w.id == id) return w.fullName;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workshopName = _workshopName();
    // The mosque is either already set on the destination or chosen here.
    final mosqueName = destination.needsMosque
        ? choice?.mosqueName
        : destination.mosque?.name;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextCustom(
                  text: destination.label,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextCustom.caption(
                text: destinationTypeLabel(l10n, destination.destinationType),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mosque picker — only for an unassigned MOST_NEEDED destination.
          if (destination.needsMosque)
            _PickerRow(
              icon: Icons.mosque_outlined,
              label: l10n.chooseMosque,
              value: mosqueName,
              onTap: onPickMosque,
            ),
          if (destination.needsMosque) const SizedBox(height: 10),
          _PickerRow(
            icon: Icons.engineering_outlined,
            label: l10n.chooseWorkshop,
            value: workshopName,
            onTap: onPickWorkshop,
          ),
        ],
      ),
    );
  }
}

/// A tappable row that shows either a placeholder label or the chosen value.
class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: ColorsCustom.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: hasValue ? ColorsCustom.primary : ColorsCustom.textHint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: hasValue ? value! : label,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasValue
                      ? ColorsCustom.textPrimary
                      : ColorsCustom.textHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ColorsCustom.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

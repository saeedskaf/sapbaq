import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/maintenance_detail_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/maintenance_labels.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_filter_bar.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/distance_badge.dart';
import 'package:sapbaq_admin/core/widgets/reason_sheet.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';
import 'package:sapbaq_admin/features/shared/presentation/photo_strip.dart';

/// Maintenance case detail + the lifecycle actions the signed-in role may run
/// on it (server-authoritative; the UI only shows what's plausibly allowed).
class MaintenanceDetailScreen extends StatelessWidget {
  final int caseId;
  const MaintenanceDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MaintenanceDetailCubit(context.read<AdminRepository>(), caseId)
            ..load(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // The queue's own title is plural now, so the single case gets its own.
      appBar: AppBar(title: TextCustom.subheading(text: l10n.mtCaseTitle)),
      body: BlocConsumer<MaintenanceDetailCubit, MaintenanceDetailState>(
        listenWhen: (a, b) => a.message != b.message && b.message != null,
        listener: (context, state) =>
            ShowMessage.error(context, state.message!),
        builder: (context, state) {
          if (state.status == LoadStatus.loading && state.item == null) {
            return const LoadingView();
          }
          if (state.status == LoadStatus.failure && state.item == null) {
            return ErrorView(
              message: state.message ?? l10n.genericError,
              retryLabel: l10n.retry,
              onRetry: () => context.read<MaintenanceDetailCubit>().load(),
            );
          }
          final c = state.item;
          if (c == null) return const SizedBox.shrink();
          return _Body(item: c, busy: state.busy);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final MaintenanceCase item;
  final bool busy;
  const _Body({required this.item, required this.busy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final equip = item.equipment;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextCustom(
                      text: (equip?.equipmentType.isNotEmpty ?? false)
                          ? equip!.equipmentType
                          : mtIssueLabel(l10n, item.issueType),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  mtChip(
                    mtStatusLabel(l10n, item.status),
                    mtStatusColor(context, item.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Row(l10n.repFieldIssue, mtIssueLabel(l10n, item.issueType)),
              _Row(l10n.repFieldDescription, item.description),
              if (equip != null) _Row(l10n.repFieldEquipmentCode, equip.code),
              if (equip != null) _Row(l10n.opsMosque, equip.mosque),
              // The distance is only present when the queue that led here was
              // sorted nearest-first; the directions button stands alone.
              if (item.distanceKm != null || item.mosqueMapsUrl != null)
                Row(
                  children: [
                    DistanceBadge(distanceKm: item.distanceKm, sorted: true),
                    const Spacer(),
                    DirectionsButton(mapsUrl: item.mosqueMapsUrl),
                  ],
                ),
              _Row(
                l10n.mtFieldReporter,
                item.reportedBy?.fullName ?? item.reporterPhone,
              ),
              _Row(
                l10n.mtFieldPriority,
                item.priority.isEmpty
                    ? ''
                    : mtPriorityLabel(l10n, item.priority),
              ),
              _Row(l10n.mtFieldCostPath, mtCostLabel(l10n, item.costPath)),
              if (item.price != null && item.price!.isNotEmpty)
                _Row(l10n.mtFieldPrice, l10n.priceKwd(item.price!)),
              _Row(l10n.mtFieldTeamLeader, item.teamLeader?.fullName ?? ''),
              _Row(l10n.mtFieldMember, item.teamMember?.fullName ?? ''),
              _Row(l10n.mtFieldStatement, item.completionStatement),
              _Row(l10n.repFieldDate, formatDateTimeOf(item.createdAt)),
              _Row(l10n.repFieldReference, item.shortReference),
              if (item.routedToManufacturer) ...[
                const SizedBox(height: 8),
                mtChip(l10n.mtManufacturerRouted, ColorsCustom.warning),
              ],
              if (item.mergedInto != null) ...[
                const SizedBox(height: 8),
                mtChip(
                  l10n.mtMergedInto(item.mergedInto!),
                  context.colors.textHint,
                ),
              ],
              if (item.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                PhotoStrip(urls: item.photoUrls),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (busy)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(color: context.colors.primary),
            ),
          )
        else
          _Actions(item: item),
      ],
    );
  }
}

/// The role- and status-gated action buttons for the case. Which actions are
/// allowed is decided by the pure [visibleMaintenanceActions] matrix
/// (FLUTTER_OPERATIONS_CENTER §3–§4); this widget only renders them.
class _Actions extends StatelessWidget {
  final MaintenanceCase item;
  const _Actions({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthBloc>().state.user;
    final isGlobal = user?.isGlobalAdmin ?? false;
    final actions = visibleMaintenanceActions(
      status: item.status,
      isDesk: user?.canTriageMaintenance ?? false,
      isLeader: isGlobal || (user != null && item.teamLeader?.id == user.id),
      canComplete:
          isGlobal ||
          (user != null &&
              (item.teamLeader?.id == user.id ||
                  item.teamMember?.id == user.id)),
      isCustomerChannel: item.isQrCustomer,
      // A team leader pulls an unassigned approved case onto his own team; the
      // server checks it's in his governorate.
      canClaim: (user?.canClaimMaintenance ?? false) && item.teamLeader == null,
    );

    final handler = _ActionHandler(context);
    final buttons = <Widget>[
      if (actions.contains(MaintenanceAction.acknowledge))
        _Btn.primary(l10n.mtAcknowledge, () => handler.acknowledge()),
      if (actions.contains(MaintenanceAction.approve))
        _Btn.primary(l10n.approveButton, () => handler.approve(item)),
      if (actions.contains(MaintenanceAction.claim))
        _Btn.primary(l10n.mtClaim, () => handler.claim()),
      if (actions.contains(MaintenanceAction.assignLeader))
        _Btn.primary(l10n.mtAssignLeader, () => handler.assignLeader()),
      if (actions.contains(MaintenanceAction.assignMember))
        _Btn.primary(l10n.mtAssignMember, () => handler.assignMember()),
      if (actions.contains(MaintenanceAction.complete))
        _Btn.primary(l10n.mtComplete, () => handler.complete()),
      if (actions.contains(MaintenanceAction.verify))
        _Btn.primary(l10n.mtVerify, () => handler.verify()),
      if (actions.contains(MaintenanceAction.setPriority))
        _Btn.neutral(l10n.mtSetPriority, () => handler.setPriority(item)),
      if (actions.contains(MaintenanceAction.duplicate))
        _Btn.neutral(l10n.mtDuplicate, () => handler.duplicate(item)),
      if (actions.contains(MaintenanceAction.cancel))
        _Btn.danger(l10n.mtCancelCase, () => handler.cancel()),
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in buttons) ...[b, const SizedBox(height: 10)],
      ],
    );
  }
}

/// Wires each action to its input dialog/sheet and reports the outcome.
class _ActionHandler {
  final BuildContext context;
  _ActionHandler(this.context);

  MaintenanceDetailCubit get _cubit => context.read<MaintenanceDetailCubit>();
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  void _done(bool ok) {
    if (ok && context.mounted) ShowMessage.success(context, _l10n.mtActionDone);
  }

  Future<void> acknowledge() async => _done(await _cubit.acknowledge());

  Future<void> claim() async {
    final ok = await showConfirmDialog(
      context,
      title: _l10n.mtClaim,
      message: _l10n.mtClaimConfirm,
      confirmLabel: _l10n.mtClaim,
    );
    if (ok == true) _done(await _cubit.claim());
  }

  Future<void> verify() async {
    final ok = await showConfirmDialog(
      context,
      message: _l10n.mtVerify,
      confirmLabel: _l10n.mtVerify,
    );
    if (ok == true) _done(await _cubit.verify());
  }

  /// Merge this customer case into a canonical one: search for other cases on
  /// the same equipment, let the user pick the canonical target, then merge.
  Future<void> duplicate(MaintenanceCase item) async {
    final code = item.equipment?.code ?? '';
    if (code.isEmpty) {
      ShowMessage.info(context, _l10n.mtDuplicateNoCode);
      return;
    }
    final cases = await _load(
      () async => (await context.read<AdminRepository>().fetchMaintenanceCases(
        search: code,
      )).results,
    );
    if (cases == null) return;
    final candidates = cases.where((c) => c.id != item.id).toList();
    if (candidates.isEmpty) {
      if (context.mounted) ShowMessage.info(context, _l10n.mtDuplicateEmpty);
      return;
    }
    if (!context.mounted) return;
    final picked = await showFilterOptionsSheet(
      context,
      title: _l10n.mtDuplicatePickHint,
      selected: '',
      options: [
        for (final c in candidates) FilterOption('${c.id}', _caseLabel(c)),
      ],
    );
    if (picked != null && picked.isNotEmpty) {
      _done(await _cubit.duplicate(int.parse(picked)));
    }
  }

  /// A one-line label for a candidate canonical case in the merge picker.
  String _caseLabel(MaintenanceCase c) {
    final ref = c.shortReference.isEmpty ? '#${c.id}' : c.shortReference;
    final mosque = c.equipment?.mosque ?? '';
    return [
      ref,
      mtStatusLabel(_l10n, c.status),
      if (mosque.isNotEmpty) mosque,
    ].join(' · ');
  }

  Future<void> cancel() async {
    final reason = await ReasonSheet.show(
      context,
      title: _l10n.mtCancelCase,
      hint: _l10n.approvalRejectHint,
      confirmLabel: _l10n.mtCancelCase,
      required: false,
      danger: true,
    );
    if (reason == null) return;
    _done(await _cubit.cancel(reason.isEmpty ? null : reason));
  }

  /// Completion is multipart now (unified-dispatch doc §4-a): the statement
  /// plus at least one photo, or the server rejects with 400.
  Future<void> complete() async {
    final result =
        await showModalBottomSheet<({String statement, List<String> paths})>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: context.colors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const _CompleteSheet(),
        );
    if (result == null) return;
    _done(await _cubit.complete(result.statement, result.paths));
  }

  Future<void> setPriority(MaintenanceCase item) async {
    final value = await _pickOption(
      title: _l10n.mtChoosePriority,
      options: [
        for (final p in MaintenanceEnums.priorities)
          (value: p, label: mtPriorityLabel(_l10n, p)),
      ],
      selected: item.priority,
    );
    if (value != null) _done(await _cubit.setPriority(value));
  }

  Future<void> approve(MaintenanceCase item) async {
    final result =
        await showModalBottomSheet<({String costPath, String? price})>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: context.colors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _ApproveSheet(suggested: item.suggestedCostPath),
        );
    if (result != null) {
      _done(
        await _cubit.approve(costPath: result.costPath, price: result.price),
      );
    }
  }

  Future<void> assignLeader() async {
    final list = await _load(
      () => context.read<AdminRepository>().fetchTeamLeaders(),
    );
    if (list == null) return;
    if (list.isEmpty) {
      if (context.mounted) ShowMessage.info(context, _l10n.mtNoLeaders);
      return;
    }
    final id = await _pickStaff(_l10n.mtChooseLeader, list);
    if (id != null) _done(await _cubit.assignTeamLeader(id));
  }

  Future<void> assignMember() async {
    final list = await _load(
      () => context.read<AdminRepository>().fetchWorkshops(),
    );
    if (list == null) return;
    if (list.isEmpty) {
      if (context.mounted) ShowMessage.info(context, _l10n.mtNoMembers);
      return;
    }
    final id = await _pickStaff(_l10n.mtChooseMember, list, showLoad: true);
    if (id != null) _done(await _cubit.assignMember(id));
  }

  /// Runs an async fetch, surfacing failures as a snackbar (returns null then).
  Future<List<T>?> _load<T>(Future<List<T>> Function() fetch) async {
    try {
      return await fetch();
    } catch (_) {
      if (context.mounted) ShowMessage.error(context, _l10n.genericError);
      return null;
    }
  }

  Future<String?> _pickOption({
    required String title,
    required List<({String value, String label})> options,
    String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _OptionSheet(title: title, options: options, selected: selected),
    );
  }

  Future<int?> _pickStaff(
    String title,
    List<Workshop> staff, {
    bool showLoad = false,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _StaffSheet(title: title, staff: staff, showLoad: showLoad),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _BtnKind kind;
  const _Btn.primary(this.label, this.onTap) : kind = _BtnKind.primary;
  const _Btn.neutral(this.label, this.onTap) : kind = _BtnKind.neutral;
  const _Btn.danger(this.label, this.onTap) : kind = _BtnKind.danger;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _BtnKind.primary => ButtonCustom.primary(text: label, onPressed: onTap),
      _BtnKind.neutral => ButtonCustom.secondary(text: label, onPressed: onTap),
      _BtnKind.danger => ButtonCustom(
        text: label,
        color: ColorsCustom.error,
        textColor: ColorsCustom.textOnPrimary,
        onPressed: onTap,
      ),
    };
  }
}

enum _BtnKind { primary, neutral, danger }

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: TextCustom(
              text: label,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextCustom(
              text: value,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single-choice option list (priority).
class _OptionSheet extends StatelessWidget {
  final String title;
  final List<({String value, String label})> options;
  final String? selected;
  const _OptionSheet({
    required this.title,
    required this.options,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          TextCustom.subheading(text: title),
          const SizedBox(height: 8),
          for (final o in options)
            ListTile(
              title: TextCustom(text: o.label, fontSize: 14),
              trailing: o.value == selected
                  ? Icon(Icons.check_rounded, color: context.colors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(o.value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// A staff picker (team leaders / members), optionally showing active load.
class _StaffSheet extends StatelessWidget {
  final String title;
  final List<Workshop> staff;
  final bool showLoad;
  const _StaffSheet({
    required this.title,
    required this.staff,
    required this.showLoad,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            TextCustom.subheading(text: title),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: staff.length,
                itemBuilder: (_, i) {
                  final s = staff[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.colors.surfaceVariant,
                      child: Icon(
                        Icons.person_rounded,
                        color: context.colors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: TextCustom(text: s.fullName, fontSize: 14),
                    subtitle: showLoad
                        ? TextCustom(
                            text: l10n.mtActiveLoad(s.activeLoad),
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(s.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable cost-path row with a leading selection indicator.
class _CostOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CostOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? context.colors.primary
                  : context.colors.textHint,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(child: TextCustom(text: label, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// The completion sheet: the statement plus at least one photo, both required
/// (unified-dispatch doc §4-a — the photos land in the COMPLETION stage).
class _CompleteSheet extends StatefulWidget {
  const _CompleteSheet();

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  /// Backend cap on completion photos (dispatch answers §Q7 — 5 max, ≥1
  /// required); block adding past it so the request never 400s.
  static const _maxPhotos = 5;

  final _statementController = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _photoPaths = [];

  @override
  void dispose() {
    _statementController.dispose();
    super.dispose();
  }

  bool _atCap() {
    if (_photoPaths.length < _maxPhotos) return false;
    final l10n = AppLocalizations.of(context)!;
    ShowMessage.error(context, l10n.mtPhotosMax(_maxPhotos));
    return true;
  }

  Future<void> _addFromCamera() async {
    final l10n = AppLocalizations.of(context)!;
    if (_atCap()) return;
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
      );
    } catch (_) {
      if (mounted) ShowMessage.error(context, l10n.pickFailed);
      return;
    }
    if (file != null && mounted) setState(() => _photoPaths.add(file!.path));
  }

  Future<void> _addFromGallery() async {
    final l10n = AppLocalizations.of(context)!;
    if (_atCap()) return;
    final List<XFile> files;
    try {
      files = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1600);
    } catch (_) {
      if (mounted) ShowMessage.error(context, l10n.pickFailed);
      return;
    }
    if (files.isNotEmpty && mounted) {
      final remaining = _maxPhotos - _photoPaths.length;
      if (files.length > remaining) {
        ShowMessage.error(context, l10n.mtPhotosMax(_maxPhotos));
      }
      setState(
        () => _photoPaths.addAll(files.take(remaining).map((f) => f.path)),
      );
    }
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    final statement = _statementController.text.trim();
    if (statement.isEmpty) {
      ShowMessage.error(context, l10n.mtStatementRequired);
      return;
    }
    if (_photoPaths.isEmpty) {
      ShowMessage.error(context, l10n.mtPhotosRequired);
      return;
    }
    Navigator.of(context).pop((
      statement: statement,
      paths: List<String>.unmodifiable(_photoPaths),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        media.viewInsets.bottom + media.padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextCustom.subheading(text: l10n.mtComplete),
          const SizedBox(height: 12),
          TextField(
            controller: _statementController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.mtFieldStatement,
              hintText: l10n.mtStatementHint,
            ),
          ),
          const SizedBox(height: 14),
          if (_photoPaths.isNotEmpty) ...[
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _LocalPhotoThumb(
                  path: _photoPaths[i],
                  onRemove: () => setState(() => _photoPaths.removeAt(i)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: ButtonCustom.secondary(
                  text: l10n.takePhoto,
                  onPressed: _addFromCamera,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ButtonCustom.secondary(
                  text: l10n.fromGallery,
                  onPressed: _addFromGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ButtonCustom.primary(text: l10n.mtComplete, onPressed: _confirm),
          const SizedBox(height: 10),
          ButtonCustom.secondary(
            text: l10n.cancelButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// One picked local photo with a remove (×) badge.
class _LocalPhotoThumb extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _LocalPhotoThumb({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        PositionedDirectional(
          top: -5,
          end: -5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: ColorsCustom.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: ColorsCustom.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The approve sheet: pick a cost path; a price is required only for
/// customer-funded repairs.
class _ApproveSheet extends StatefulWidget {
  final String suggested;
  const _ApproveSheet({required this.suggested});

  @override
  State<_ApproveSheet> createState() => _ApproveSheetState();
}

class _ApproveSheetState extends State<_ApproveSheet> {
  String? _costPath;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (MaintenanceEnums.approveCostPaths.contains(widget.suggested)) {
      _costPath = widget.suggested;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    final cp = _costPath;
    if (cp == null) return;
    if (cp == 'CUSTOMER_PAID') {
      final price = _priceController.text.trim();
      if (price.isEmpty || (double.tryParse(price) ?? 0) <= 0) {
        ShowMessage.error(context, l10n.mtPriceRequired);
        return;
      }
      Navigator.of(context).pop((costPath: cp, price: price));
    } else {
      Navigator.of(context).pop((costPath: cp, price: null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        media.viewInsets.bottom + media.padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextCustom.subheading(text: l10n.mtApproveTitle),
          const SizedBox(height: 4),
          TextCustom(
            text: l10n.mtChooseCostPath,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
          if (MaintenanceEnums.approveCostPaths.contains(widget.suggested)) ...[
            const SizedBox(height: 6),
            TextCustom(
              text: l10n.mtSuggested(mtCostLabel(l10n, widget.suggested)),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ],
          const SizedBox(height: 8),
          for (final cp in MaintenanceEnums.approveCostPaths)
            _CostOption(
              label: mtCostLabel(l10n, cp),
              selected: _costPath == cp,
              onTap: () => setState(() => _costPath = cp),
            ),
          if (_costPath == 'CUSTOMER_PAID') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(labelText: l10n.mtPriceKwd),
            ),
          ],
          const SizedBox(height: 20),
          ButtonCustom.primary(
            text: l10n.approveButton,
            onPressed: _costPath == null ? null : _confirm,
          ),
          const SizedBox(height: 10),
          ButtonCustom.secondary(
            text: l10n.cancelButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

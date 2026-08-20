import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/location/location_for_role.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/utils/media_url.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/in_app_media.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/fulfilment_task.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/fulfilment_tasks_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/maintenance_labels.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_filter_bar.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/distance_badge.dart';
import 'package:sapbaq_admin/features/shared/presentation/model_thumb.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The marketplace fulfilment-task queue (unified-dispatch doc §1): each task
/// walks the assignment chain office → team leader → handler and is settled
/// with a statement + photo. A WATER task covers a whole restock flag; an
/// EQUIPMENT task installs one funded unit. Which button shows is decided by
/// the pure [visibleFulfilmentActions] matrix; the server stays authoritative.
class FulfilmentTasksScreen extends StatelessWidget {
  const FulfilmentTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FulfilmentTasksCubit(
        context.read<AdminRepository>(),
        location: locationForRole(context),
      )..load(),
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatefulWidget {
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      context.read<FulfilmentTasksCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.ftTitle),
        actions: [
          // The contributions ledger stayed view-only (amounts/states); the
          // queue is where the work happens, so the ledger hangs off it.
          IconButton(
            tooltip: l10n.ctTitle,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.pushNamed(AppRoutes.opsContributionsName),
          ),
        ],
      ),
      body: Column(
        children: [
          const _TasksFilterBar(),
          BlocBuilder<FulfilmentTasksCubit, FulfilmentTasksState>(
            buildWhen: (a, b) => a.sortedByDistance != b.sortedByDistance,
            builder: (context, state) =>
                NearestFirstHint(sorted: state.sortedByDistance),
          ),
          Expanded(
            child: BlocConsumer<FulfilmentTasksCubit, FulfilmentTasksState>(
              listenWhen: (a, b) => a.message != b.message && b.message != null,
              listener: (context, state) =>
                  ShowMessage.error(context, state.message!),
              builder: (context, state) {
                if (state.status == LoadStatus.loading) {
                  return const LoadingView();
                }
                if (state.status == LoadStatus.failure) {
                  return ErrorView(
                    message: state.message ?? l10n.genericError,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<FulfilmentTasksCubit>().load(),
                  );
                }
                if (state.items.isEmpty) {
                  return EmptyView(
                    message: l10n.opsEmptyQueue,
                    icon: Icons.fact_check_outlined,
                  );
                }
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<FulfilmentTasksCubit>().load(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.colors.primary,
                            ),
                          ),
                        );
                      }
                      final t = state.items[i];
                      return _TaskCard(
                        item: t,
                        busy: state.actioningId == t.id,
                        sorted: state.sortedByDistance,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The status filter pill. '' = the server's default (open tasks).
class _TasksFilterBar extends StatelessWidget {
  const _TasksFilterBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<FulfilmentTasksCubit, FulfilmentTasksState>(
      buildWhen: (a, b) => a.statusFilter != b.statusFilter,
      builder: (context, state) {
        final cubit = context.read<FulfilmentTasksCubit>();
        return OpsFilterBar(
          pills: [
            FilterPill(
              label:
                  '${l10n.opsFilterStatus}: '
                  '${state.statusFilter.isEmpty ? l10n.ftFilterOpen : ftStatusLabel(l10n, state.statusFilter)}',
              active: state.statusFilter.isNotEmpty,
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterStatus,
                  selected: state.statusFilter,
                  options: [
                    FilterOption('', l10n.ftFilterOpen),
                    for (final s in FulfilmentTaskEnums.statuses)
                      FilterOption(s, ftStatusLabel(l10n, s)),
                  ],
                );
                if (value != null) cubit.setStatus(value);
              },
            ),
          ],
        );
      },
    );
  }
}

String ftStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'AWAITING_ASSIGN' => l10n.ftStatusAwaitingAssign,
  'ASSIGNED_TO_TEAM' => l10n.ftStatusAssignedToTeam,
  'ASSIGNED' => l10n.ftStatusAssigned,
  'DONE' => l10n.ftStatusDone,
  'CANCELLED' => l10n.ftStatusCancelled,
  _ => status,
};

Color _ftStatusColor(BuildContext context, String status) => switch (status) {
  'AWAITING_ASSIGN' => ColorsCustom.warning,
  'ASSIGNED_TO_TEAM' || 'ASSIGNED' => context.colors.primary,
  'DONE' => ColorsCustom.success,
  'CANCELLED' => context.colors.danger,
  _ => context.colors.textHint,
};

String _ftKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'WATER' => l10n.ctKindWater,
  'EQUIPMENT' => l10n.ctKindEquipment,
  _ => kind,
};

class _TaskCard extends StatelessWidget {
  final FulfilmentTask item;
  final bool busy;

  /// Whether the queue was sorted nearest-first — gates the distance badge.
  final bool sorted;

  const _TaskCard({
    required this.item,
    required this.busy,
    this.sorted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cover = item.modelThumb;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (cover != null)
                ModelThumb(
                  url: cover,
                  size: 44,
                  zoomUrl: item.modelImage ?? cover,
                  zoomUrls: item.modelImages,
                )
              else
                Icon(
                  item.kind == 'WATER'
                      ? Icons.water_drop_rounded
                      : Icons.kitchen_rounded,
                  size: 22,
                  color: context.colors.primary,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: _ftKindLabel(l10n, item.kind),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              mtChip(
                ftStatusLabel(l10n, item.status),
                _ftStatusColor(context, item.status),
              ),
            ],
          ),
          if (item.mosque != null && item.mosque!.name.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Meta(
                    icon: Icons.mosque_outlined,
                    text: [
                      item.mosque!.name,
                      item.mosque!.locationLine,
                    ].where((s) => s.isNotEmpty).join(' — '),
                  ),
                ),
                DistanceBadge(distanceKm: item.distanceKm, sorted: sorted),
                DirectionsButton(mapsUrl: item.mosque!.mapsUrl),
              ],
            ),
          ],
          if (item.targetSummary.isNotEmpty) ...[
            const SizedBox(height: 4),
            _Meta(icon: Icons.info_outline_rounded, text: item.targetSummary),
          ],
          if (item.modelName.isNotEmpty) ...[
            const SizedBox(height: 4),
            _Meta(icon: Icons.kitchen_outlined, text: item.modelName),
          ],
          // An equipment task only exists once its campaign reached 100%, so
          // this line is the handler's proof the unit is fully paid for.
          if (item.fundedOfTarget.isNotEmpty) ...[
            const SizedBox(height: 4),
            _Meta(
              icon: Icons.savings_outlined,
              text: l10n.ftFullyFunded(item.fundedOfTarget),
            ),
          ],
          if (item.teamLeader != null) ...[
            const SizedBox(height: 4),
            _Meta(
              icon: Icons.supervisor_account_outlined,
              text: '${l10n.mtFieldTeamLeader}: ${item.teamLeader!.fullName}',
            ),
          ],
          if (item.handler != null) ...[
            const SizedBox(height: 4),
            _Meta(
              icon: Icons.engineering_outlined,
              text: '${l10n.ftFieldHandler}: ${item.handler!.fullName}',
            ),
          ],
          const SizedBox(height: 4),
          _Meta(
            icon: Icons.schedule_outlined,
            text: formatDateTimeOf(item.doneAt ?? item.createdAt),
          ),
          if (item.isDone) _Settlement(item: item),
          if (busy)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: CircularProgressIndicator(color: context.colors.primary),
              ),
            )
          else
            _Actions(item: item),
        ],
      ),
    );
  }
}

/// The proof shown once the task is DONE: the statement plus the photo.
class _Settlement extends StatelessWidget {
  final FulfilmentTask item;
  const _Settlement({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photo = item.photo;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[
            GestureDetector(
              onTap: () => openInAppImage(context, url: photo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  resolveMediaUrl(photo) ?? photo,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: context.colors.surfaceVariant,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: context.colors.textHint,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: l10n.ftStatement,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(height: 2),
                TextCustom(text: item.statement, fontSize: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The role- and status-gated dispatch button for the task, one at a time —
/// each stage has exactly one next step.
class _Actions extends StatelessWidget {
  final FulfilmentTask item;
  const _Actions({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthBloc>().state.user;
    final actions = visibleFulfilmentActions(
      status: item.status,
      isDesk: user?.canAssignTaskLeader ?? false,
      isBypass: user?.canBypassTaskChain ?? false,
      isLeader: user != null && item.teamLeader?.id == user.id,
      isHandler: user != null && item.handler?.id == user.id,
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    final handler = _ActionHandler(context, item);
    // A bypass manager sees both "assign leader" and "assign handler" on a new
    // task, so the buttons stack — space them apart.
    final buttons = <Widget>[
      if (actions.contains(FulfilmentAction.assignLeader))
        ButtonCustom.primary(
          text: l10n.mtAssignLeader,
          onPressed: handler.assignLeader,
        ),
      if (actions.contains(FulfilmentAction.assignHandler))
        ButtonCustom.primary(
          text: l10n.ftAssignHandler,
          onPressed: handler.assignHandler,
        ),
      if (actions.contains(FulfilmentAction.fulfil))
        ButtonCustom.primary(text: l10n.ftFulfil, onPressed: handler.fulfil),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            buttons[i],
          ],
        ],
      ),
    );
  }
}

/// Wires each dispatch action to its picker/form and reports the outcome.
class _ActionHandler {
  final BuildContext context;
  final FulfilmentTask item;
  _ActionHandler(this.context, this.item);

  FulfilmentTasksCubit get _cubit => context.read<FulfilmentTasksCubit>();
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  void _done(bool ok, String message) {
    if (ok && context.mounted) ShowMessage.success(context, message);
  }

  Future<void> assignLeader() async {
    final list = await _load(
      () => context.read<AdminRepository>().fetchTaskTeamLeaders(item.id),
    );
    if (list == null) return;
    if (list.isEmpty) {
      if (context.mounted) ShowMessage.info(context, _l10n.mtNoLeaders);
      return;
    }
    final id = await _pickStaff(_l10n.mtChooseLeader, list);
    if (id != null) {
      _done(await _cubit.assignLeader(item.id, id), _l10n.mtActionDone);
    }
  }

  Future<void> assignHandler() async {
    final list = await _load(
      () => context.read<AdminRepository>().fetchTaskHandlers(item.id),
    );
    if (list == null) return;
    if (list.isEmpty) {
      if (context.mounted) ShowMessage.info(context, _l10n.ftNoHandlers);
      return;
    }
    final id = await _pickStaff(_l10n.ftChooseHandler, list);
    if (id != null) {
      _done(await _cubit.assignHandler(item.id, id), _l10n.mtActionDone);
    }
  }

  Future<void> fulfil() async {
    final result =
        await showModalBottomSheet<({String statement, String path})>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: context.colors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const _FulfilSheet(),
        );
    if (result == null) return;
    _done(
      await _cubit.fulfil(
        item.id,
        statement: result.statement,
        photoPath: result.path,
      ),
      _l10n.ftFulfilled,
    );
  }

  Future<List<T>?> _load<T>(Future<List<T>> Function() fetch) async {
    try {
      return await fetch();
    } catch (_) {
      if (context.mounted) ShowMessage.error(context, _l10n.genericError);
      return null;
    }
  }

  Future<int?> _pickStaff(String title, List<Workshop> staff) {
    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StaffSheet(title: title, staff: staff),
    );
  }
}

/// The settlement form: a statement plus exactly one proof photo, both
/// required (the server 400s otherwise).
class _FulfilSheet extends StatefulWidget {
  const _FulfilSheet();

  @override
  State<_FulfilSheet> createState() => _FulfilSheetState();
}

class _FulfilSheetState extends State<_FulfilSheet> {
  final _statementController = TextEditingController();
  final _picker = ImagePicker();
  String? _photoPath;

  @override
  void dispose() {
    _statementController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
    } catch (_) {
      if (mounted) ShowMessage.error(context, l10n.pickFailed);
      return;
    }
    if (file != null && mounted) setState(() => _photoPath = file!.path);
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    final statement = _statementController.text.trim();
    if (statement.isEmpty) {
      ShowMessage.error(context, l10n.ftStatementRequired);
      return;
    }
    final path = _photoPath;
    if (path == null) {
      ShowMessage.error(context, l10n.ftPhotoRequired);
      return;
    }
    Navigator.of(context).pop((statement: statement, path: path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final path = _photoPath;
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
          TextCustom.subheading(text: l10n.ftFulfil),
          const SizedBox(height: 12),
          TextField(
            controller: _statementController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.ftStatement,
              hintText: l10n.ftStatementHint,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (path != null) ...[
                _PickedPhotoThumb(
                  path: path,
                  onClear: () => setState(() => _photoPath = null),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ButtonCustom.secondary(
                        text: l10n.takePhoto,
                        onPressed: () => _pick(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ButtonCustom.secondary(
                        text: l10n.fromGallery,
                        onPressed: () => _pick(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ButtonCustom.primary(text: l10n.ftFulfil, onPressed: _confirm),
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

/// The picked local photo as a thumbnail with a clear (×) badge.
class _PickedPhotoThumb extends StatelessWidget {
  final String path;
  final VoidCallback onClear;
  const _PickedPhotoThumb({required this.path, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          ),
        ),
        PositionedDirectional(
          top: -6,
          end: -6,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: ColorsCustom.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: ColorsCustom.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A staff picker (leaders / handlers). The task-scoped assignable endpoints
/// carry no active-load figure, so none is shown.
class _StaffSheet extends StatelessWidget {
  final String title;
  final List<Workshop> staff;
  const _StaffSheet({required this.title, required this.staff});

  @override
  Widget build(BuildContext context) {
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

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: context.colors.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

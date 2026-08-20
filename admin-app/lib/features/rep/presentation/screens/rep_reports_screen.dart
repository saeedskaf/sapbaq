import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';
import 'package:sapbaq_admin/features/rep/data/rep_repository.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';
import 'package:sapbaq_admin/features/shared/presentation/photo_strip.dart';

/// «بلاغاتي» — everything the rep has raised, in three tabs: maintenance
/// reports (3 reporter-facing statuses), water flags, and equipment requests.
/// Each card surfaces every field the API returns; the app-bar action and the
/// pull-to-refresh both reload all tabs.
class RepReportsScreen extends StatefulWidget {
  /// Which tab to open on — a notification about one need type lands on its
  /// tab. See [repReportsTabIndex].
  final int initialTab;

  const RepReportsScreen({super.key, this.initialTab = 0});

  @override
  State<RepReportsScreen> createState() => _RepReportsScreenState();
}

/// Resolves the `?tab=` query of [AppRoutes.repReports] to a tab index,
/// defaulting to maintenance for an absent or unknown value.
int repReportsTabIndex(String? tab) => switch (tab) {
  AppRoutes.repReportsTabWater => 1,
  AppRoutes.repReportsTabEquipment => 2,
  _ => 0,
};

class _RepReportsScreenState extends State<RepReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    initialIndex: widget.initialTab,
    vsync: this,
  );

  /// Bumped by the app-bar refresh action; every tab listens and reloads.
  final ValueNotifier<int> _refreshTick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.repNavReports),
        actions: [
          IconButton(
            tooltip: l10n.repRefresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshTick.value++,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: context.colors.primary,
          tabs: [
            Tab(text: l10n.repTabMaintenance),
            Tab(text: l10n.repTabWater),
            Tab(text: l10n.repTabEquipment),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MaintenanceTab(refreshTick: _refreshTick),
          _WaterTab(refreshTick: _refreshTick),
          _EquipmentTab(refreshTick: _refreshTick),
        ],
      ),
    );
  }
}

/// Shared list plumbing for the three tabs. Reloads on pull-to-refresh and
/// whenever [refreshTick] changes (the app-bar refresh action).
class _TabList<T> extends StatefulWidget {
  final Future<List<T>> Function(RepRepository) fetch;
  final Widget Function(T) itemBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final Listenable refreshTick;

  const _TabList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.refreshTick,
  });

  @override
  State<_TabList<T>> createState() => _TabListState<T>();
}

class _TabListState<T> extends State<_TabList<T>>
    with AutomaticKeepAliveClientMixin {
  List<T> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.refreshTick.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refreshTick.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.fetch(context.read<RepRepository>());
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(
        message: _error!,
        retryLabel: l10n.retry,
        onRetry: _load,
      );
    }
    if (_items.isEmpty) {
      // Wrap the empty state so pull-to-refresh still works on an empty tab.
      return RefreshIndicator(
        color: context.colors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: EmptyView(
                message: widget.emptyMessage,
                icon: widget.emptyIcon,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          floatingNavBarClearance(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => widget.itemBuilder(_items[i]),
      ),
    );
  }
}

class _MaintenanceTab extends StatelessWidget {
  final Listenable refreshTick;
  const _MaintenanceTab({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TabList<RepMaintenanceReport>(
      refreshTick: refreshTick,
      fetch: (repo) => repo.maintenanceReports(),
      emptyMessage: l10n.repNoReports,
      emptyIcon: Icons.build_outlined,
      itemBuilder: (report) => _ReportCard(
        icon: Icons.build_rounded,
        title: report.equipmentType.isEmpty
            ? l10n.repTabMaintenance
            : report.equipmentType,
        // The list now also holds cases management raised for this mosque —
        // say so, so the imam doesn't read them as his own reports.
        chip: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (report.isFromManagement) ...[
              _chip(l10n.mtChannelManager, context.colors.textHint),
              const SizedBox(width: 6),
            ],
            _reportStatusChip(context, l10n, report.status),
          ],
        ),
        details: [
          _Detail(l10n.repFieldIssue, report.issueTypeDisplay),
          _Detail(l10n.repFieldEquipmentCode, report.equipmentCode),
          _Detail(l10n.repFieldDescription, report.description),
          _Detail(l10n.repFieldDate, formatDateTimeOf(report.createdAt)),
          _Detail(l10n.repFieldResolvedAt, formatDateTimeOf(report.resolvedAt)),
          _Detail(l10n.repFieldReference, report.shortReference),
        ],
        photoUrls: [for (final p in report.photos) p.imageUrl],
      ),
    );
  }
}

class _WaterTab extends StatelessWidget {
  final Listenable refreshTick;
  const _WaterTab({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TabList<RepWaterFlag>(
      refreshTick: refreshTick,
      fetch: (repo) => repo.waterFlags(),
      emptyMessage: l10n.repNoReports,
      emptyIcon: Icons.water_drop_outlined,
      itemBuilder: (flag) => _ReportCard(
        icon: Icons.water_drop_rounded,
        title: l10n.repWaterFlagTitle,
        chip: _rawStatusChip(context, l10n, flag.status),
        details: [
          _Detail(l10n.repFieldDate, formatDateTimeOf(flag.createdAt)),
          _Detail(l10n.repFieldApprovedAt, formatDateTimeOf(flag.approvedAt)),
          _Detail(l10n.repFieldFulfilledAt, formatDateTimeOf(flag.fulfilledAt)),
        ],
      ),
    );
  }
}

class _EquipmentTab extends StatelessWidget {
  final Listenable refreshTick;
  const _EquipmentTab({required this.refreshTick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TabList<RepEquipmentRequest>(
      refreshTick: refreshTick,
      fetch: (repo) => repo.equipmentRequests(),
      emptyMessage: l10n.repNoReports,
      emptyIcon: Icons.kitchen_outlined,
      itemBuilder: (request) => _ReportCard(
        icon: Icons.kitchen_rounded,
        title: request.typeName.isEmpty
            ? l10n.repTabEquipment
            : request.typeName,
        chip: _rawStatusChip(context, l10n, request.status),
        details: [
          _Detail(l10n.repFieldNote, request.note),
          _Detail(l10n.repFieldDate, formatDateTimeOf(request.createdAt)),
          _Detail(
            l10n.repFieldApprovedAt,
            formatDateTimeOf(request.approvedAt),
          ),
          _Detail(
            l10n.repFieldFulfilledAt,
            formatDateTimeOf(request.fulfilledAt),
          ),
        ],
        // Rejection reason stands out in the error colour when present.
        emphasis: request.rejectReason.isEmpty
            ? null
            : _Detail(l10n.repFieldRejectReason, request.rejectReason),
      ),
    );
  }
}

Widget _reportStatusChip(
  BuildContext context,
  AppLocalizations l10n,
  RepReportStatus status,
) {
  final (label, color) = switch (status) {
    RepReportStatus.submitted => (
      l10n.repStatusSubmitted,
      context.colors.primary,
    ),
    RepReportStatus.inProgress => (
      l10n.repStatusInProgress,
      ColorsCustom.warning,
    ),
    RepReportStatus.resolved => (l10n.repStatusResolved, ColorsCustom.success),
    RepReportStatus.unknown => ('—', context.colors.textHint),
  };
  return _chip(label, color);
}

Widget _rawStatusChip(
  BuildContext context,
  AppLocalizations l10n,
  String status,
) {
  final (label, color) = switch (status) {
    'SUBMITTED' => (l10n.repStatusSubmitted, context.colors.primary),
    'APPROVED' => (l10n.repStatusApproved, ColorsCustom.warning),
    'FULFILLED' => (l10n.repStatusFulfilled, ColorsCustom.success),
    'REJECTED' => (l10n.repStatusRejected, context.colors.danger),
    'CANCELLED' => (l10n.repStatusCancelled, context.colors.danger),
    _ => (status, context.colors.textHint),
  };
  return _chip(label, color);
}

Widget _chip(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(10),
  ),
  child: TextCustom(
    text: label,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: color,
  ),
);

/// A single label/value pair. Skipped entirely when [value] is empty.
class _Detail {
  final String label;
  final String value;
  const _Detail(this.label, this.value);

  bool get isEmpty => value.trim().isEmpty;
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget chip;
  final List<_Detail> details;

  /// An optional highlighted row (e.g. a rejection reason) rendered in the
  /// error colour below the regular details.
  final _Detail? emphasis;

  /// Optional attached photo URLs (maintenance reports) — a tappable strip.
  final List<String> photoUrls;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.chip,
    required this.details,
    this.emphasis,
    this.photoUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final rows = details.where((d) => !d.isEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: context.colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: TextCustom(
                  text: title,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              chip,
            ],
          ),
          for (final d in rows) ...[
            const SizedBox(height: 8),
            _DetailRow(label: d.label, value: d.value),
          ],
          if (emphasis != null && !emphasis!.isEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              label: emphasis!.label,
              value: emphasis!.value,
              valueColor: context.colors.danger,
            ),
          ],
          if (photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            PhotoStrip(urls: photoUrls),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: TextCustom(
            text: label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextCustom(
            text: value,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? context.colors.textPrimary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

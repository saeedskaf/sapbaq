import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/activity_entry.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/activity_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// My-activity feed (§8): the current user's own recent actions, newest first,
/// paginated.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ActivityCubit(context.read<AdminRepository>())..load(),
      child: const _ActivityView(),
    );
  }
}

class _ActivityView extends StatefulWidget {
  const _ActivityView();

  @override
  State<_ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<_ActivityView> {
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
      context.read<ActivityCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.activityTitle)),
      body: BlocBuilder<ActivityCubit, ActivityState>(
        builder: (context, state) {
          if (state.status == LoadStatus.loading) {
            return const LoadingView();
          }
          if (state.status == LoadStatus.failure) {
            return ErrorView(
              message: state.message ?? l10n.genericError,
              retryLabel: l10n.retry,
              onRetry: () => context.read<ActivityCubit>().load(),
            );
          }
          if (state.entries.isEmpty) {
            return EmptyView(
              message: l10n.emptyActivity,
              icon: Icons.history_rounded,
            );
          }
          return RefreshIndicator(
            color: ColorsCustom.primary,
            onRefresh: () => context.read<ActivityCubit>().load(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.entries.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= state.entries.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ColorsCustom.primary,
                      ),
                    ),
                  );
                }
                return _ActivityRow(entry: state.entries[i], l10n: l10n);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityEntry entry;
  final AppLocalizations l10n;
  const _ActivityRow({required this.entry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final time = formatShortDateTime(entry.createdAt);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorsCustom.secondaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(entry.action),
              color: ColorsCustom.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: _labelFor(entry.action),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  TextCustom(
                    text: time,
                    fontSize: 12,
                    color: ColorsCustom.textHint,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Map a dotted action code to an Arabic label, falling back to the raw code
  /// for actions we don't have a translation for yet.
  String _labelFor(String action) {
    switch (action) {
      case 'destination.assigned':
        return l10n.actionAssigned;
      case 'destination.reassigned':
        return l10n.actionReassigned;
      case 'order.cancel':
      case 'order.cancelled':
        return l10n.actionCancelled;
      default:
        return action;
    }
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'destination.assigned':
        return Icons.assignment_ind_outlined;
      case 'destination.reassigned':
        return Icons.swap_horiz_rounded;
      case 'order.cancel':
      case 'order.cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }
}

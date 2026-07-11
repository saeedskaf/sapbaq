import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/approval.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/approvals_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/pill.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Maker-Checker approvals inbox (§10): approvals pending on the current user,
/// each approvable or rejectable inline. Configured on web, actioned here.
class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ApprovalsCubit(context.read<AdminRepository>())..load(),
      child: const _ApprovalsView(),
    );
  }
}

class _ApprovalsView extends StatefulWidget {
  const _ApprovalsView();

  @override
  State<_ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<_ApprovalsView> {
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
      context.read<ApprovalsCubit>().loadMore();
    }
  }

  Future<void> _approve(BuildContext context, Approval a) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await context.read<ApprovalsCubit>().approve(a.id);
    if (ok && context.mounted) {
      ShowMessage.success(context, l10n.approveSuccess);
    }
  }

  Future<void> _reject(BuildContext context, Approval a) async {
    final cubit = context.read<ApprovalsCubit>();
    final l10n = AppLocalizations.of(context)!;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RejectSheet(),
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await cubit.reject(a.id, reason);
    if (ok && context.mounted) ShowMessage.success(context, l10n.rejectSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.approvalsTitle)),
      body: BlocConsumer<ApprovalsCubit, ApprovalsState>(
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
              onRetry: () => context.read<ApprovalsCubit>().load(),
            );
          }
          if (state.items.isEmpty) {
            return EmptyView(
              message: l10n.emptyApprovals,
              icon: Icons.fact_check_outlined,
            );
          }
          return RefreshIndicator(
            color: context.colors.primary,
            onRefresh: () => context.read<ApprovalsCubit>().load(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= state.items.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primary,
                      ),
                    ),
                  );
                }
                final approval = state.items[i];
                return _ApprovalCard(
                  approval: approval,
                  busy: state.actioningId == approval.id,
                  onApprove: () => _approve(context, approval),
                  onReject: () => _reject(context, approval),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final Approval approval;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.approval,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  String _actionLabel(AppLocalizations l10n) {
    switch (approval.action) {
      case 'order.cancel':
      case 'order.cancelled':
        return l10n.actionCancelled;
      default:
        return approval.action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextCustom(
                  text: _actionLabel(l10n),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (approval.targetType == 'Order' && approval.targetId != null)
                Pill(
                  text: l10n.orderRefShort('#${approval.targetId}'),
                  color: context.colors.primary,
                  background: context.colors.surfaceVariant,
                  fontSize: 11,
                ),
            ],
          ),
          if (approval.maker != null) ...[
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.person_outline,
              text: '${l10n.approvalMakerLabel}: ${approval.maker!.fullName}',
            ),
          ],
          if (approval.payloadReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            _MetaRow(icon: Icons.notes_outlined, text: approval.payloadReason),
          ],
          if (approval.amount != null && approval.amount!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.payments_outlined,
              text: l10n.priceKwd(approval.amount!),
            ),
          ],
          if ((approval.createdAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.schedule_outlined,
              text: formatShortDateTime(approval.createdAt),
            ),
          ],
          if (approval.isPending) ...[
            const SizedBox(height: 14),
            if (busy)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ButtonCustom(
                      text: l10n.rejectButton,
                      color: ColorsCustom.error,
                      textColor: ColorsCustom.textOnPrimary,
                      onPressed: onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ButtonCustom.primary(
                      text: l10n.approveButton,
                      onPressed: onApprove,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

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

/// Collects a required rejection reason; pops the trimmed string.
class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextCustom.subheading(
            text: l10n.approvalRejectTitle,
            color: ColorsCustom.error,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.approvalRejectHint),
          ),
          const SizedBox(height: 20),
          ButtonCustom(
            text: l10n.confirmReject,
            color: ColorsCustom.error,
            textColor: ColorsCustom.textOnPrimary,
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
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

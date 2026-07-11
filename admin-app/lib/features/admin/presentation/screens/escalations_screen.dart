import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/reason_sheet.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/escalation.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/escalations_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/pill.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Escalations directed to me (§9): list + resolve, plus a FAB to raise a new
/// escalation to my direct manager.
class EscalationsScreen extends StatelessWidget {
  const EscalationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EscalationsCubit(context.read<AdminRepository>())..load(),
      child: const _EscalationsView(),
    );
  }
}

class _EscalationsView extends StatefulWidget {
  const _EscalationsView();

  @override
  State<_EscalationsView> createState() => _EscalationsViewState();
}

class _EscalationsViewState extends State<_EscalationsView> {
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
      context.read<EscalationsCubit>().loadMore();
    }
  }

  Future<void> _resolve(BuildContext context, Escalation e) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await context.read<EscalationsCubit>().resolve(e.id);
    if (ok && context.mounted) {
      ShowMessage.success(context, l10n.resolveSuccess);
    }
  }

  Future<void> _raise(BuildContext context) async {
    final cubit = context.read<EscalationsCubit>();
    final l10n = AppLocalizations.of(context)!;
    final reason = await ReasonSheet.show(
      context,
      title: l10n.raiseEscalationTitle,
      hint: l10n.raiseEscalationHint,
      confirmLabel: l10n.raiseEscalationTitle,
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await cubit.raise(reason);
    if (ok && context.mounted) {
      ShowMessage.success(context, l10n.escalationRaised);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.escalationsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _raise(context),
        backgroundColor: ColorsCustom.brandMint,
        foregroundColor: ColorsCustom.onMint,
        icon: const Icon(Icons.campaign_outlined),
        label: TextCustom(
          text: l10n.raiseEscalationTitle,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ColorsCustom.onMint,
        ),
      ),
      body: BlocConsumer<EscalationsCubit, EscalationsState>(
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
              onRetry: () => context.read<EscalationsCubit>().load(),
            );
          }
          if (state.items.isEmpty) {
            return EmptyView(
              message: l10n.emptyEscalations,
              icon: Icons.campaign_outlined,
            );
          }
          return RefreshIndicator(
            color: context.colors.primary,
            onRefresh: () => context.read<EscalationsCubit>().load(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
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
                final escalation = state.items[i];
                return _EscalationCard(
                  escalation: escalation,
                  busy: state.actioningId == escalation.id,
                  onResolve: () => _resolve(context, escalation),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  final Escalation escalation;
  final bool busy;
  final VoidCallback onResolve;

  const _EscalationCard({
    required this.escalation,
    required this.busy,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final open = escalation.isOpen;
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
                  text: escalation.reason,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                text: open ? l10n.statusOpen : l10n.statusResolved,
                color: open ? ColorsCustom.warning : ColorsCustom.success,
                background: context.colors.surfaceVariant,
                fontSize: 11,
              ),
            ],
          ),
          if (escalation.order != null) ...[
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.confirmation_number_outlined,
              text: l10n.orderRefShort(escalation.displayCode),
            ),
          ],
          if (escalation.raisedBy != null) ...[
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.person_outline,
              text:
                  '${l10n.escalationRaisedByLabel}: ${escalation.raisedBy!.fullName}',
            ),
          ],
          if ((escalation.createdAt ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.schedule_outlined,
              text: formatShortDateTime(escalation.createdAt),
            ),
          ],
          if (open) ...[
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
              ButtonCustom.primary(
                text: l10n.resolveButton,
                onPressed: onResolve,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/date_format.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/support/data/models/support_ticket.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';
import 'package:sapbaq/features/support/presentation/bloc/support_cubit.dart';
import 'package:sapbaq/features/support/presentation/bloc/support_unread_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

String ticketStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'OPEN':
      return l10n.ticketStatusOpen;
    case 'IN_PROGRESS':
      return l10n.ticketStatusInProgress;
    case 'RESOLVED':
      return l10n.ticketStatusResolved;
    case 'CLOSED':
      return l10n.ticketStatusClosed;
    default:
      return status;
  }
}

Color ticketStatusColor(BuildContext context, String status) {
  switch (status) {
    case 'OPEN':
      return context.colors.primary;
    case 'IN_PROGRESS':
      return ColorsCustom.warning;
    case 'RESOLVED':
      return ColorsCustom.success;
    default:
      return context.colors.textHint;
  }
}

/// "Support" — the user's tickets, with a button to open a new one.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) =>
          SupportCubit(context.read<SupportRepository>())..load(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: TextCustom.subheading(text: l10n.supportTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _newTicket(context),
            icon: const Icon(Icons.add_comment_outlined),
            label: TextCustom(
              text: l10n.newTicket,
              color: context.colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          body: BlocConsumer<SupportCubit, SupportState>(
            listenWhen: (a, b) =>
                (b.message != null && a.message != b.message) ||
                (a.status != b.status && b.status == LoadStatus.success),
            listener: (context, state) {
              if (state.message != null) {
                ShowMessage.error(context, state.message!);
              }
              // Reconcile the app-wide unread badge with the freshly loaded list.
              if (state.status == LoadStatus.success) {
                context.read<SupportUnreadCubit>().refresh();
              }
            },
            builder: (context, state) {
              if (state.status == LoadStatus.loading) {
                return const LoadingView();
              }
              if (state.status == LoadStatus.failure) {
                return ErrorView(
                  message: state.message ?? l10n.comingSoon,
                  retryLabel: l10n.retry,
                  onRetry: () => context.read<SupportCubit>().load(),
                );
              }
              if (state.tickets.isEmpty) {
                return EmptyView(
                  message: l10n.emptyTickets,
                  icon: Icons.support_agent_outlined,
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + 96,
                ),
                itemCount: state.tickets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _TicketCard(ticket: state.tickets[i]),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _newTicket(BuildContext context) async {
    final cubit = context.read<SupportCubit>();
    final created = await context.pushNamed<bool>(AppRoutes.newTicketName);
    if (created == true) cubit.load();
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  const _TicketCard({required this.ticket});

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<SupportCubit>();
    await context.pushNamed(
      AppRoutes.ticketDetailName,
      pathParameters: {'id': '${ticket.id}'},
    );
    // Refresh so the per-ticket unread badge clears after viewing.
    cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final last = ticket.lastMessage;
    final preview = last == null
        ? null
        : (last.isMine ? '${l10n.lastMessageYou}${last.body}' : last.body);
    final date = formatShortDate(ticket.lastActivityAt ?? ticket.createdAt);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextCustom(
                      text: ticket.subject,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ticket.hasUnread) ...[
                    const SizedBox(width: 8),
                    _UnreadBadge(count: ticket.unreadCount),
                  ],
                  const SizedBox(width: 8),
                  _StatusChip(status: ticket.status),
                ],
              ),
              if (preview != null && preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextCustom(
                  text: preview,
                  fontSize: 13,
                  color: ticket.hasUnread
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                  fontWeight: ticket.hasUnread
                      ? FontWeight.w600
                      : FontWeight.w400,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (date.isNotEmpty) ...[
                const SizedBox(height: 6),
                TextCustom(
                  text: date,
                  fontSize: 12,
                  color: context.colors.textHint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small count badge shown on a ticket with unread replies.
class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorsCustom.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextCustom(
        text: '$count',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = ticketStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextCustom(
        text: ticketStatusLabel(l10n, status),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

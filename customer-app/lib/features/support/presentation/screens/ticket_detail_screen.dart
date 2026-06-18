import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/support/data/models/support_ticket.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';
import 'package:sapbaq/features/support/presentation/bloc/ticket_cubit.dart';
import 'package:sapbaq/features/support/presentation/screens/support_screen.dart'
    show ticketStatusColor, ticketStatusLabel;
import 'package:sapbaq/l10n/app_localizations.dart';

/// A support ticket thread with a reply composer. Bubbles align by `is_mine`.
class TicketDetailScreen extends StatelessWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TicketCubit(context.read<SupportRepository>(), ticketId)..load(),
      child: const _TicketDetailView(),
    );
  }
}

class _TicketDetailView extends StatefulWidget {
  const _TicketDetailView();

  @override
  State<_TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends State<_TicketDetailView> {
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _send() {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    context.read<TicketCubit>().sendReply(text);
    _reply.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<TicketCubit, TicketState>(
          buildWhen: (a, b) => a.ticket?.subject != b.ticket?.subject,
          builder: (context, state) => TextCustom.subheading(
            text: state.ticket?.subject ?? l10n.supportTitle,
          ),
        ),
      ),
      body: BlocConsumer<TicketCubit, TicketState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) =>
            ShowMessage.error(context, state.message!),
        builder: (context, state) {
          if (state.status == LoadStatus.loading && state.ticket == null) {
            return const LoadingView();
          }
          if (state.status == LoadStatus.failure && state.ticket == null) {
            return ErrorView(
              message: state.message ?? l10n.comingSoon,
              retryLabel: l10n.retry,
              onRetry: () => context.read<TicketCubit>().load(),
            );
          }
          final ticket = state.ticket;
          if (ticket == null) return const SizedBox.shrink();
          return Column(
            children: [
              _StatusHeader(status: ticket.status),
              Expanded(
                child: ticket.messages.isEmpty
                    ? EmptyView(
                        message: l10n.replyHint,
                        icon: Icons.forum_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ticket.messages.length,
                        itemBuilder: (_, i) =>
                            _MessageBubble(message: ticket.messages[i]),
                      ),
              ),
              _ReplyBar(
                controller: _reply,
                sending: state.sending,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final String status;
  const _StatusHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = ticketStatusColor(context, status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.colors.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          TextCustom(
            text: ticketStatusLabel(l10n, status),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? context.colors.primary : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextCustom(
          text: message.body,
          fontSize: 14,
          color: isMine ? context.colors.onPrimary : context.colors.textPrimary,
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.replyHint,
                filled: true,
                fillColor: context.colors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: context.colors.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: sending ? null : onSend,
              child: SizedBox(
                width: 44,
                height: 44,
                child: sending
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: context.colors.onPrimary,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

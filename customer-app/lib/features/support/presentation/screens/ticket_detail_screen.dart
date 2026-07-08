import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/in_app_media.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/support/data/models/support_ticket.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';
import 'package:sapbaq/features/support/presentation/bloc/support_unread_cubit.dart';
import 'package:sapbaq/features/support/presentation/bloc/ticket_cubit.dart';
import 'package:sapbaq/features/support/presentation/screens/support_screen.dart'
    show ticketStatusColor, ticketStatusLabel;
import 'package:sapbaq/l10n/app_localizations.dart';

/// A support ticket thread with a reply composer. Bubbles render by
/// `sender_type`; replies can carry an image; a closed ticket disables the
/// composer.
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
  final _picker = ImagePicker();
  XFile? _image;
  bool _readSignaled = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _send() {
    final text = _reply.text.trim();
    if (text.isEmpty && _image == null) return;
    context.read<TicketCubit>().sendReply(body: text, image: _image);
    _reply.clear();
    setState(() => _image = null);
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: TextCustom(text: l10n.photoFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: TextCustom(text: l10n.photoFromCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null && mounted) setState(() => _image = picked);
    } catch (_) {
      if (mounted) {
        ShowMessage.error(context, AppLocalizations.of(context)!.imagePickFailed);
      }
    }
  }

  /// Opening a ticket marks it read; reflect that in the app-wide badge once.
  void _signalReadOnce(SupportTicket ticket) {
    if (_readSignaled || !ticket.hasUnread) return;
    _readSignaled = true;
    context.read<SupportUnreadCubit>().markedOneRead();
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
        listenWhen: (a, b) =>
            (b.message != null && a.message != b.message) ||
            (a.ticket == null && b.ticket != null),
        listener: (context, state) {
          if (state.message != null) ShowMessage.error(context, state.message!);
          if (state.ticket != null) _signalReadOnce(state.ticket!);
        },
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
              if (ticket.canReply)
                _ReplyBar(
                  controller: _reply,
                  image: _image,
                  sending: state.sending,
                  onPickImage: _pickImage,
                  onClearImage: () => setState(() => _image = null),
                  onSend: _send,
                )
              else
                const _ClosedNote(),
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
    // SYSTEM lines (e.g. "reopened") render as a centered, muted notice.
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextCustom(
              text: message.body,
              fontSize: 12,
              color: context.colors.textHint,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isMine = message.isMine;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.76;
    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (message.isStaff &&
              (message.senderName ?? '').isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6, top: 4),
              child: TextCustom(
                text: message.senderName!,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.textHint,
              ),
            ),
            const SizedBox(height: 2),
          ],
          for (final att in message.attachments)
            _AttachmentThumb(attachment: att, maxWidth: maxWidth),
          if (message.body.isNotEmpty)
            Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? context.colors.primaryFill
                    : context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextCustom(
                text: message.body,
                fontSize: 14,
                color: isMine
                    ? context.colors.onPrimary
                    : context.colors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// A tappable image attachment thumbnail; opens the full image in-app.
class _AttachmentThumb extends StatelessWidget {
  final TicketAttachment attachment;
  final double maxWidth;
  const _AttachmentThumb({required this.attachment, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(attachment.url);
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () => openInAppImage(context, url: attachment.url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: 220,
            ),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 160,
                height: 120,
                color: context.colors.surfaceVariant,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: context.colors.textHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the composer when the ticket is closed.
class _ClosedNote extends StatelessWidget {
  const _ClosedNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: context.colors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: TextCustom(
              text: l10n.ticketClosedNote,
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final XFile? image;
  final bool sending;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onSend;

  const _ReplyBar({
    required this.controller,
    required this.image,
    required this.sending,
    required this.onPickImage,
    required this.onClearImage,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image != null) _ImagePreview(image: image!, onClear: onClearImage),
          Row(
            children: [
              IconButton(
                onPressed: sending ? null : onPickImage,
                tooltip: l10n.attachImage,
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: context.colors.primary,
                ),
              ),
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
                color: context.colors.primaryFill,
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
        ],
      ),
    );
  }
}

/// Selected-attachment preview above the composer, with a remove button.
class _ImagePreview extends StatelessWidget {
  final XFile image;
  final VoidCallback onClear;
  const _ImagePreview({required this.image, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(image.path),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            PositionedDirectional(
              top: -6,
              end: -6,
              child: IconButton(
                onPressed: onClear,
                iconSize: 18,
                icon: CircleAvatar(
                  radius: 11,
                  backgroundColor: context.colors.surface,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

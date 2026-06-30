import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/support/data/models/support_ticket.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';

class TicketState extends Equatable {
  final LoadStatus status;
  final SupportTicket? ticket;
  final bool sending;
  final String? message;

  const TicketState({
    this.status = LoadStatus.initial,
    this.ticket,
    this.sending = false,
    this.message,
  });

  bool get canReply => ticket?.canReply ?? true;

  TicketState copyWith({
    LoadStatus? status,
    SupportTicket? ticket,
    bool? sending,
    String? message,
  }) {
    return TicketState(
      status: status ?? this.status,
      ticket: ticket ?? this.ticket,
      sending: sending ?? this.sending,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, ticket, sending, message];
}

/// A single ticket's thread, with reply sending. Opening the ticket marks it
/// read; posting a reply re-fetches it (so the new message — and any reopen —
/// show immediately).
class TicketCubit extends Cubit<TicketState> {
  final SupportRepository _repo;
  final int ticketId;

  TicketCubit(this._repo, this.ticketId) : super(const TicketState());

  Future<void> load() async {
    emit(const TicketState(status: LoadStatus.loading));
    try {
      final ticket = await _repo.fetchTicket(ticketId);
      emit(TicketState(status: LoadStatus.success, ticket: ticket));
      _markReadBestEffort();
    } on ApiException catch (e) {
      emit(TicketState(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Mark the ticket read in the background; a failure here is harmless.
  void _markReadBestEffort() {
    if (state.ticket?.hasUnread != true) return;
    _repo.markRead(ticketId).catchError((_) {});
  }

  Future<void> sendReply({String? body, XFile? image}) async {
    final hasText = (body ?? '').trim().isNotEmpty;
    if ((!hasText && image == null) || state.sending) return;
    emit(state.copyWith(sending: true, message: null));
    try {
      await _repo.addMessage(ticketId, body: body, image: image);
      final ticket = await _repo.fetchTicket(ticketId);
      emit(TicketState(status: LoadStatus.success, ticket: ticket));
    } on ApiException catch (e) {
      emit(state.copyWith(sending: false, message: e.message));
    }
  }
}

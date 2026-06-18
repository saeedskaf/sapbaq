import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/support/data/models/support_ticket.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';

class SupportState extends Equatable {
  final LoadStatus status;
  final List<SupportTicket> tickets;
  final String? message;

  const SupportState({
    this.status = LoadStatus.initial,
    this.tickets = const [],
    this.message,
  });

  @override
  List<Object?> get props => [status, tickets, message];
}

/// The user's list of support tickets.
class SupportCubit extends Cubit<SupportState> {
  final SupportRepository _repo;
  SupportCubit(this._repo) : super(const SupportState());

  Future<void> load() async {
    emit(const SupportState(status: LoadStatus.loading));
    try {
      final tickets = await _repo.fetchTickets();
      emit(SupportState(status: LoadStatus.success, tickets: tickets));
    } on ApiException catch (e) {
      emit(SupportState(status: LoadStatus.failure, message: e.message));
    }
  }
}

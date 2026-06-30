import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/features/support/data/support_repository.dart';

/// App-wide count of support tickets with unread replies. Drives the badge on
/// the Profile → Support row. Loaded on sign-in and refreshed after the support
/// list loads or a ticket is opened (marked read).
class SupportUnreadCubit extends Cubit<int> {
  final SupportRepository _repo;
  SupportUnreadCubit(this._repo) : super(0);

  Future<void> refresh() async {
    try {
      emit(await _repo.unreadCount());
    } catch (_) {
      // Best-effort: a failed badge fetch shouldn't disturb the UI.
    }
  }

  /// Alias for clarity at call sites that load on sign-in.
  Future<void> load() => refresh();

  /// Optimistically drop the badge by one when a ticket with unread replies is
  /// opened (it becomes read). Avoids a refresh race with the server.
  void markedOneRead() => emit(state > 0 ? state - 1 : 0);

  void reset() => emit(0);
}

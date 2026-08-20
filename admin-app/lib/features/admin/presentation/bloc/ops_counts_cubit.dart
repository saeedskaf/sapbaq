import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/ops_counts.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';

class OpsCountsState extends Equatable {
  final OpsCounts counts;

  /// True only while the first load is in flight — a refresh keeps the old
  /// numbers on screen instead of blanking the badge and the cards.
  final bool loading;

  const OpsCountsState({this.counts = const OpsCounts(), this.loading = false});

  @override
  List<Object?> get props => [counts, loading];
}

/// The operations-center workload, shared by the nav badge and the hub cards so
/// both show the same numbers from one fetch.
///
/// Never emits a failure: the counts decorate screens that work without them, so
/// a network blip leaves the last known numbers (or zeros) rather than an error.
class OpsCountsCubit extends Cubit<OpsCountsState> {
  final AdminRepository _repo;
  OpsCountsCubit(this._repo) : super(const OpsCountsState());

  bool _inFlight = false;

  /// Load the role-scoped workload. Cheap to call on every visit to the hub —
  /// overlapping calls collapse into the one already running. Never surfaces an
  /// error: the counts decorate screens that work without them, so a failure
  /// leaves the last known numbers rather than blanking the badge. [user] only
  /// gates the pre-sign-in call; the endpoint itself is role-scoped server-side.
  Future<void> load(User? user) async {
    if (user == null || _inFlight) return;
    _inFlight = true;
    emit(
      OpsCountsState(counts: state.counts, loading: state.counts.total == 0),
    );
    try {
      final counts = await _repo.fetchOpsCounts();
      if (!isClosed) emit(OpsCountsState(counts: counts));
    } catch (_) {
      // Keep the last known numbers (or zeros) — the badge never errors.
    } finally {
      _inFlight = false;
      if (!isClosed && state.loading) {
        emit(OpsCountsState(counts: state.counts));
      }
    }
  }

  /// Sign-out: drop the previous account's numbers so the next session never
  /// flashes a stale badge before its own load lands.
  void reset() => emit(const OpsCountsState());
}

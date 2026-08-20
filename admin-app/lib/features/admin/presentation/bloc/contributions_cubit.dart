import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/utils/month_filter.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/contribution.dart';

/// The view-only contributions ledger (amounts/states — unified-dispatch doc
/// §0). Defaults to the `PAID` bucket in the current month; the user can
/// switch status (including `all`), kind, and month. Settlement happens
/// elsewhere: water/equipment through their fulfilment task, maintenance when
/// its case resolves — so items leave the PAID bucket on their own.
class ContributionsState extends Equatable {
  final LoadStatus status;
  final List<AdminContribution> items;
  final bool hasMore;
  final bool loadingMore;
  final String? message;

  /// `YYYY-MM`, or '' for all periods.
  final String month;

  /// A contribution `status` value (`all` = every status). Defaults to `PAID`.
  final String statusFilter;

  /// A `kind` value (WATER/MAINTENANCE/EQUIPMENT), or '' for any.
  final String kindFilter;

  const ContributionsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
    this.month = '',
    this.statusFilter = 'PAID',
    this.kindFilter = '',
  });

  ContributionsState copyWith({
    LoadStatus? status,
    List<AdminContribution>? items,
    bool? hasMore,
    bool? loadingMore,
    String? message,
    String? month,
    String? statusFilter,
    String? kindFilter,
  }) {
    return ContributionsState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
      month: month ?? this.month,
      statusFilter: statusFilter ?? this.statusFilter,
      kindFilter: kindFilter ?? this.kindFilter,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    hasMore,
    loadingMore,
    message,
    month,
    statusFilter,
    kindFilter,
  ];
}

class ContributionsCubit extends Cubit<ContributionsState> {
  final AdminRepository _repo;
  ContributionsCubit(this._repo)
    : super(ContributionsState(month: currentMonthKey()));

  int _page = 1;

  Future<void> load() async {
    _page = 1;
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        items: const [],
        loadingMore: false,
        message: null,
      ),
    );
    try {
      final page = await _repo.fetchContributions(
        page: 1,
        status: state.statusFilter,
        kind: state.kindFilter,
        month: state.month,
      );
      emit(
        state.copyWith(
          status: LoadStatus.success,
          items: page.results,
          hasMore: page.hasMore,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != LoadStatus.success) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.fetchContributions(
        page: _page + 1,
        status: state.statusFilter,
        kind: state.kindFilter,
        month: state.month,
      );
      _page += 1;
      emit(
        state.copyWith(
          items: [...state.items, ...page.results],
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }

  void setMonth(String month) {
    if (month == state.month) return;
    emit(state.copyWith(month: month));
    load();
  }

  void setStatus(String value) {
    if (value == state.statusFilter) return;
    emit(state.copyWith(statusFilter: value));
    load();
  }

  void setKind(String value) {
    if (value == state.kindFilter) return;
    emit(state.copyWith(kindFilter: value));
    load();
  }
}

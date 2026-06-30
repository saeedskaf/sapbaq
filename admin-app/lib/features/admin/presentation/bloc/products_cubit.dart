import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_product.dart';

class ProductsState extends Equatable {
  final LoadStatus status;
  final List<AdminProduct> items;
  final String search;
  final bool hasMore;
  final bool loadingMore;

  /// Product whose availability is being toggled (spinner). Always overwritten.
  final int? togglingId;
  final String? message;

  const ProductsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.search = '',
    this.hasMore = false,
    this.loadingMore = false,
    this.togglingId,
    this.message,
  });

  ProductsState copyWith({
    LoadStatus? status,
    List<AdminProduct>? items,
    String? search,
    bool? hasMore,
    bool? loadingMore,
    int? togglingId,
    String? message,
  }) {
    return ProductsState(
      status: status ?? this.status,
      items: items ?? this.items,
      search: search ?? this.search,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      togglingId: togglingId,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, search, hasMore, loadingMore, togglingId, message];
}

class ProductsCubit extends Cubit<ProductsState> {
  final AdminRepository _repo;
  ProductsCubit(this._repo) : super(const ProductsState());

  int _page = 1;

  Future<void> load() => _loadFirstPage();

  Future<void> search(String query) {
    final q = query.trim();
    if (q == state.search) return Future.value();
    emit(state.copyWith(search: q));
    return _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      items: const [],
      loadingMore: false,
      message: null,
    ));
    try {
      final page = await _repo.fetchProducts(
        page: 1,
        search: state.search.isEmpty ? null : state.search,
      );
      emit(state.copyWith(
        status: LoadStatus.success,
        items: page.results,
        hasMore: page.hasMore,
      ));
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
      final page = await _repo.fetchProducts(
        page: _page + 1,
        search: state.search.isEmpty ? null : state.search,
      );
      _page += 1;
      emit(state.copyWith(
        items: [...state.items, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Toggle a product's availability optimistically, reverting on failure.
  Future<bool> setAvailability(
    int id,
    bool isAvailable, {
    String? reason,
  }) async {
    final previous = state.items;
    final updated = state.items
        .map((p) => p.id == id ? p.copyWith(isAvailable: isAvailable) : p)
        .toList();
    emit(state.copyWith(togglingId: id, items: updated, message: null));
    try {
      await _repo.setProductAvailability(
        id,
        isAvailable: isAvailable,
        reason: reason,
      );
      emit(state.copyWith(items: updated)); // clears togglingId
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(items: previous, message: e.message));
      return false;
    }
  }
}

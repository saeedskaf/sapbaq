import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/notifications/data/models/notification_preferences.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';

class NotificationPreferencesState extends Equatable {
  final LoadStatus status;
  final NotificationPreferences prefs;
  final String? message;

  const NotificationPreferencesState({
    this.status = LoadStatus.initial,
    this.prefs = const NotificationPreferences(),
    this.message,
  });

  @override
  List<Object?> get props => [status, prefs, message];
}

class NotificationPreferencesCubit
    extends Cubit<NotificationPreferencesState> {
  final NotificationsRepository _repo;

  NotificationPreferencesCubit(this._repo)
      : super(const NotificationPreferencesState());

  Future<void> load() async {
    emit(const NotificationPreferencesState(status: LoadStatus.loading));
    try {
      final prefs = await _repo.fetchPreferences();
      emit(NotificationPreferencesState(
        status: LoadStatus.success,
        prefs: prefs,
      ));
    } on ApiException catch (e) {
      emit(NotificationPreferencesState(
        status: LoadStatus.failure,
        message: e.message,
      ));
    }
  }

  /// Flip one category. Updates optimistically, then reverts (with a message)
  /// if the server rejects it.
  Future<void> toggle(String key, bool value) async {
    final previous = state.prefs;
    emit(NotificationPreferencesState(
      status: LoadStatus.success,
      prefs: _apply(previous, key, value),
    ));
    try {
      final saved = await _repo.updatePreferences({key: value});
      emit(NotificationPreferencesState(
        status: LoadStatus.success,
        prefs: saved,
      ));
    } on ApiException catch (e) {
      emit(NotificationPreferencesState(
        status: LoadStatus.success,
        prefs: previous,
        message: e.message,
      ));
    }
  }

  NotificationPreferences _apply(
    NotificationPreferences p,
    String key,
    bool value,
  ) {
    switch (key) {
      case 'order_updates':
        return p.copyWith(orderUpdates: value);
      case 'reviews':
        return p.copyWith(reviews: value);
      case 'gifts':
        return p.copyWith(gifts: value);
      case 'promotions':
        return p.copyWith(promotions: value);
      default:
        return p;
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';

class NotificationsState extends Equatable {
  final LoadStatus status;
  final List<AppNotification> items;
  final String? message;

  const NotificationsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.message,
  });

  @override
  List<Object?> get props => [status, items, message];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repo;
  NotificationsCubit(this._repo) : super(const NotificationsState());

  Future<void> load() async {
    emit(const NotificationsState(status: LoadStatus.loading));
    try {
      final items = await _repo.fetchNotifications();
      emit(NotificationsState(status: LoadStatus.success, items: items));
    } on ApiException catch (e) {
      emit(NotificationsState(status: LoadStatus.failure, message: e.message));
    }
  }
}

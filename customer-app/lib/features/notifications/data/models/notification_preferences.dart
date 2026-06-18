import 'package:equatable/equatable.dart';

/// The user's notification opt-ins from `GET /notifications/preferences/`.
/// Four boolean categories; the backend honours each (it won't send muted
/// categories). All default to `true`.
class NotificationPreferences extends Equatable {
  final bool orderUpdates;
  final bool reviews;
  final bool gifts;
  final bool promotions;

  const NotificationPreferences({
    this.orderUpdates = true,
    this.reviews = true,
    this.gifts = true,
    this.promotions = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      orderUpdates: json['order_updates'] as bool? ?? true,
      reviews: json['reviews'] as bool? ?? true,
      gifts: json['gifts'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? reviews,
    bool? gifts,
    bool? promotions,
  }) {
    return NotificationPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      reviews: reviews ?? this.reviews,
      gifts: gifts ?? this.gifts,
      promotions: promotions ?? this.promotions,
    );
  }

  @override
  List<Object?> get props => [orderUpdates, reviews, gifts, promotions];
}

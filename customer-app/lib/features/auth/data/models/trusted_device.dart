import 'package:equatable/equatable.dart';

/// A device the user has trusted, from `GET /auth/device/trusted/`.
///
/// [current] marks the device making the request (the backend flags it when the
/// call passes `?device_id=`); the UI shows it as "this device" and doesn't
/// offer to revoke it.
class TrustedDevice extends Equatable {
  final int id;
  final String deviceName;
  final bool current;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  const TrustedDevice({
    required this.id,
    required this.deviceName,
    this.current = false,
    this.lastUsedAt,
    this.createdAt,
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      id: json['id'] as int,
      deviceName: (json['device_name'] ?? '').toString(),
      current: json['current'] as bool? ?? false,
      lastUsedAt: DateTime.tryParse((json['last_used_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [id, deviceName, current, lastUsedAt, createdAt];
}

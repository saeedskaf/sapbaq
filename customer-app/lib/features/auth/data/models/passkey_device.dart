import 'package:equatable/equatable.dart';

/// A registered passkey (one per device), from `GET /auth/passkey/devices/`.
class PasskeyDevice extends Equatable {
  final int id;
  final String deviceName;
  final String? aaguid;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  const PasskeyDevice({
    required this.id,
    required this.deviceName,
    this.aaguid,
    this.lastUsedAt,
    this.createdAt,
  });

  factory PasskeyDevice.fromJson(Map<String, dynamic> json) {
    return PasskeyDevice(
      id: json['id'] as int,
      deviceName: (json['device_name'] ?? '').toString(),
      aaguid: json['aaguid'] as String?,
      lastUsedAt: DateTime.tryParse((json['last_used_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [id, deviceName, aaguid, lastUsedAt, createdAt];
}

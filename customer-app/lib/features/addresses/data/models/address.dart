import 'package:equatable/equatable.dart';

/// A saved delivery address (`/addresses/`). `area` is the only required field;
/// the rest are optional. Exactly one address can be [isDefault] (the backend
/// enforces that — setting one default clears the others).
class Address extends Equatable {
  final int id;
  final String label;
  final String area;
  final String block;
  final String street;
  final String building;
  final String details;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String? createdAt;

  const Address({
    required this.id,
    this.label = '',
    required this.area,
    this.block = '',
    this.street = '',
    this.building = '',
    this.details = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return Address(
      id: json['id'] as int,
      label: (json['label'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      block: (json['block'] ?? '').toString(),
      street: (json['street'] ?? '').toString(),
      building: (json['building'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  /// The write payload for POST/PATCH (server-managed fields omitted).
  Map<String, dynamic> toPayload() => {
    'label': label,
    'area': area,
    'block': block,
    'street': street,
    'building': building,
    'details': details,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'is_default': isDefault,
  };

  /// A single-line, direction-neutral summary (area · block · street · …).
  String get summary => [
    area,
    block,
    street,
    building,
    details,
  ].where((p) => p.trim().isNotEmpty).join('، ');

  @override
  List<Object?> get props => [
    id,
    label,
    area,
    block,
    street,
    building,
    details,
    latitude,
    longitude,
    isDefault,
  ];
}

import 'package:equatable/equatable.dart';

/// A mosque (delivery destination).
class Mosque extends Equatable {
  final int id;
  final String name;
  final String area;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? image;
  final String? notes;

  const Mosque({
    required this.id,
    required this.name,
    this.area = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.image,
    this.notes,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory Mosque.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic value) =>
        value == null ? null : double.tryParse(value.toString());
    return Mosque(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: parseCoord(json['latitude']),
      longitude: parseCoord(json['longitude']),
      image: json['image'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Parse a GeoJSON Feature from `/mosques/map/`:
  /// `{id, geometry:{coordinates:[lng, lat]}, properties:{name, area}}`.
  factory Mosque.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final coords = (geometry is Map && geometry['coordinates'] is List)
        ? geometry['coordinates'] as List
        : const [];
    final properties = (feature['properties'] as Map?) ?? const {};
    return Mosque(
      id: feature['id'] as int,
      name: (properties['name'] ?? '').toString(),
      area: (properties['area'] ?? '').toString(),
      // GeoJSON order is [longitude, latitude].
      longitude: coords.isNotEmpty ? double.tryParse(coords[0].toString()) : null,
      latitude: coords.length > 1 ? double.tryParse(coords[1].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, name, area, address, latitude, longitude];
}

import 'package:equatable/equatable.dart';

/// A mosque (delivery destination). The admin/driver backend includes a
/// ready-to-open [mapsUrl] (Google Maps); it can be null when the mosque has no
/// coordinates — fall back to [address], which is always present.
class Mosque extends Equatable {
  final int id;
  final String name;
  final String area;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;

  const Mosque({
    required this.id,
    required this.name,
    this.area = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.mapsUrl,
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
      mapsUrl: json['maps_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, area, address, latitude, longitude];
}

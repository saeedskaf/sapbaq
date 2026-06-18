import 'package:equatable/equatable.dart';

/// A delivery-proof file uploaded by the driver for a destination:
/// `{id, file, media_type, note, uploaded_at, destination_id}`.
class DeliveryProof extends Equatable {
  final int id;
  final String file;
  final String mediaType; // IMAGE | VIDEO
  final String note;
  final String? uploadedAt;
  final int? destinationId;

  const DeliveryProof({
    required this.id,
    required this.file,
    required this.mediaType,
    this.note = '',
    this.uploadedAt,
    this.destinationId,
  });

  bool get isVideo => mediaType == 'VIDEO';

  factory DeliveryProof.fromJson(Map<String, dynamic> json) {
    return DeliveryProof(
      id: json['id'] as int? ?? 0,
      file: (json['file'] ?? '').toString(),
      mediaType: (json['media_type'] ?? 'IMAGE').toString(),
      note: (json['note'] ?? '').toString(),
      uploadedAt: json['uploaded_at'] as String?,
      destinationId: json['destination_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, file, mediaType, note];
}

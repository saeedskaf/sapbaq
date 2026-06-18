import 'package:equatable/equatable.dart';

/// A delivery proof (photo/video + note) the driver uploads on completing a
/// destination. [destinationId] ties it to an order destination, or is null for
/// an order-level proof.
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
    this.mediaType = 'IMAGE',
    this.note = '',
    this.uploadedAt,
    this.destinationId,
  });

  bool get isImage => mediaType.toUpperCase() == 'IMAGE';
  bool get isVideo => mediaType.toUpperCase() == 'VIDEO';

  factory DeliveryProof.fromJson(Map<String, dynamic> json) {
    return DeliveryProof(
      id: json['id'] as int,
      file: (json['file'] ?? '').toString(),
      mediaType: (json['media_type'] ?? 'IMAGE').toString(),
      note: (json['note'] ?? '').toString(),
      uploadedAt: json['uploaded_at'] as String?,
      destinationId: json['destination_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, file, mediaType, note, uploadedAt, destinationId];
}

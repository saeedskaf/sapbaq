import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final int id;
  final int rating;
  final String comment;
  final String? createdAt;

  const Review({
    required this.id,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      rating: json['rating'] as int? ?? 0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, rating, comment];
}

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/support/data/models/support_ticket.dart';

/// Support tickets for the signed-in user.
class SupportRepository {
  final Dio _dio;
  SupportRepository(this._dio);

  /// The user's tickets, ordered by most recent activity (server-side).
  /// Optional [status] / [hasUnread] filters.
  Future<List<SupportTicket>> fetchTickets({
    String? status,
    bool hasUnread = false,
  }) {
    return guardApi(() async {
      final params = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (hasUnread) 'has_unread': 'true',
      };
      final res = await _dio.get(
        ApiEndpoints.supportTickets,
        queryParameters: params.isEmpty ? null : params,
      );
      final data = res.data;
      if (data is Map && data['results'] is List) {
        return PaginatedResponse.fromJson(
          Map<String, dynamic>.from(data),
          SupportTicket.fromJson,
        ).results;
      }
      return (data as List)
          .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<SupportTicket> fetchTicket(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.supportTicket(id));
      return SupportTicket.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Number of tickets that have at least one unread (staff/system) message.
  Future<int> unreadCount() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.supportUnreadCount);
      final data = Map<String, dynamic>.from(res.data as Map);
      return data['count'] as int? ?? 0;
    });
  }

  /// Mark the ticket read (zeroes its unread count). Idempotent (204).
  Future<void> markRead(int id) {
    return guardApi(() => _dio.post(ApiEndpoints.supportTicketRead(id)));
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    String? category,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.supportTickets,
        data: {
          'subject': subject,
          'body': body,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return SupportTicket.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Add a reply. Sends multipart when an [image] is attached, else JSON.
  /// A reply to a resolved ticket reopens it; a reply to a closed ticket is
  /// rejected by the backend (409) with a display-ready message.
  Future<void> addMessage(int id, {String? body, XFile? image}) {
    return guardApi(() async {
      final text = (body ?? '').trim();
      if (image != null) {
        final form = FormData.fromMap({
          if (text.isNotEmpty) 'body': text,
          'image': await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        });
        await _dio.post(ApiEndpoints.supportTicketMessages(id), data: form);
      } else {
        await _dio.post(
          ApiEndpoints.supportTicketMessages(id),
          data: {'body': text},
        );
      }
    });
  }
}

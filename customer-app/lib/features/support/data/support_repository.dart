import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/support/data/models/support_ticket.dart';

/// Support tickets for the signed-in user.
class SupportRepository {
  final Dio _dio;
  SupportRepository(this._dio);

  Future<List<SupportTicket>> fetchTickets() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.supportTickets);
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

  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.supportTickets,
        data: {'subject': subject, 'body': body},
      );
      return SupportTicket.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Add a reply. A reply to a resolved ticket reopens it server-side.
  Future<void> addMessage(int id, String body) {
    return guardApi(() async {
      await _dio.post(
        ApiEndpoints.supportTicketMessages(id),
        data: {'body': body},
      );
    });
  }
}

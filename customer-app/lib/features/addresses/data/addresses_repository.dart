import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/addresses/data/models/address.dart';

/// CRUD for the signed-in user's saved addresses. Each user sees only their own.
class AddressesRepository {
  final Dio _dio;
  AddressesRepository(this._dio);

  Future<List<Address>> fetchAll() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.addresses);
      final data = res.data;
      // Tolerate either a paginated envelope or a plain list.
      if (data is Map && data['results'] is List) {
        return PaginatedResponse.fromJson(
          Map<String, dynamic>.from(data),
          Address.fromJson,
        ).results;
      }
      return (data as List)
          .map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<Address> create(Map<String, dynamic> payload) {
    return guardApi(() async {
      final res = await _dio.post(ApiEndpoints.addresses, data: payload);
      return Address.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  Future<Address> update(int id, Map<String, dynamic> payload) {
    return guardApi(() async {
      final res = await _dio.patch(ApiEndpoints.address(id), data: payload);
      return Address.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  Future<void> delete(int id) {
    return guardApi(() async {
      await _dio.delete(ApiEndpoints.address(id));
    });
  }
}

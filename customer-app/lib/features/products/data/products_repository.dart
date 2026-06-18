import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/features/products/data/models/product_category.dart';

class ProductsRepository {
  final Dio _dio;
  ProductsRepository(this._dio);

  /// All product categories (unpaginated, sorted server-side).
  Future<List<ProductCategory>> fetchCategories() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.productCategories);
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false);
      }
      return const <ProductCategory>[];
    });
  }

  /// First page of products, optionally filtered by category.
  Future<List<Product>> fetchProducts({int? categoryId, String? search}) {
    return guardApi(() async {
      final path = categoryId != null
          ? ApiEndpoints.productsByCategory(categoryId)
          : ApiEndpoints.products;
      final res = await _dio.get(
        path,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final page = PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        Product.fromJson,
      );
      return page.results;
    });
  }

  Future<Product> fetchProduct(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.product(id));
      return Product.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }
}

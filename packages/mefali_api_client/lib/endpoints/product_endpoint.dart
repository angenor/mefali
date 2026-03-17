import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints catalogue produits (merchant self-service).
class ProductEndpoint {
  const ProductEndpoint(this._dio);

  final Dio _dio;

  /// Liste les produits du marchand connecte.
  Future<List<Product>> getMyProducts() async {
    final response = await _dio.get<Map<String, dynamic>>('/products');

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['products'] as List;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cree un produit avec photo optionnelle.
  Future<Product> createProduct({
    required String name,
    required int price,
    String? description,
    int? stock,
    String? imagePath,
  }) async {
    final formMap = <String, dynamic>{
      'name': name,
      'price': price.toString(),
    };
    if (description != null) formMap['description'] = description;
    if (stock != null) formMap['stock'] = stock.toString();
    if (imagePath != null) {
      formMap['file'] = await MultipartFile.fromFile(
        imagePath,
        contentType: MediaType.parse('image/webp'),
      );
    }

    final formData = FormData.fromMap(formMap);
    final response = await _dio.post<Map<String, dynamic>>(
      '/products',
      data: formData,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  /// Met a jour un produit avec photo optionnelle.
  Future<Product> updateProduct({
    required String productId,
    String? name,
    int? price,
    String? description,
    int? stock,
    String? imagePath,
  }) async {
    final formMap = <String, dynamic>{};
    if (name != null) formMap['name'] = name;
    if (price != null) formMap['price'] = price.toString();
    if (description != null) formMap['description'] = description;
    if (stock != null) formMap['stock'] = stock.toString();
    if (imagePath != null) {
      formMap['file'] = await MultipartFile.fromFile(
        imagePath,
        contentType: MediaType.parse('image/webp'),
      );
    }

    final formData = FormData.fromMap(formMap);
    final response = await _dio.put<Map<String, dynamic>>(
      '/products/$productId',
      data: formData,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  /// Supprime un produit (soft delete).
  Future<void> deleteProduct(String productId) async {
    await _dio.delete<void>('/products/$productId');
  }
}

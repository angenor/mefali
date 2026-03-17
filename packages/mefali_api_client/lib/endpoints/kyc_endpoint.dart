import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints KYC livreur.
class KycEndpoint {
  const KycEndpoint(this._dio);

  final Dio _dio;

  /// Liste les livreurs en attente de verification KYC.
  Future<List<User>> getPendingDrivers() async {
    final response = await _dio.get<Map<String, dynamic>>('/kyc/pending');
    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['users'] as List;
    return list
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Recupere le resume KYC d'un livreur (infos + documents + sponsor).
  Future<KycSummaryResponse> getKycSummary(String userId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/kyc/$userId');
    final data = response.data!['data'] as Map<String, dynamic>;
    return KycSummaryResponse.fromJson(data);
  }

  /// Upload un document KYC (multipart: document_type + file).
  Future<KycDocument> uploadDocument({
    required String userId,
    required KycDocumentType documentType,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'document_type': documentType.name,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/kyc/$userId/documents',
      data: formData,
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return KycDocument.fromJson(data['document'] as Map<String, dynamic>);
  }

  /// Active le livreur apres verification KYC.
  Future<User> activateDriver(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/kyc/$userId/activate',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }
}

/// Reponse resume KYC (user + documents + sponsor).
class KycSummaryResponse {
  const KycSummaryResponse({
    required this.user,
    required this.documents,
    this.sponsor,
  });

  factory KycSummaryResponse.fromJson(Map<String, dynamic> json) {
    return KycSummaryResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      documents: (json['documents'] as List)
          .map((e) => KycDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      sponsor: json['sponsor'] != null
          ? User.fromJson(json['sponsor'] as Map<String, dynamic>)
          : null,
    );
  }

  final User user;
  final List<KycDocument> documents;
  final User? sponsor;
}

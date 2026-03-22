import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints de parrainage.
class SponsorshipEndpoint {
  const SponsorshipEndpoint(this._dio);

  final Dio _dio;

  /// Recupere la liste des filleuls du driver connecte.
  Future<MySponsorshipsResponse> getMySponsored() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sponsorships/me',
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Invalid response: missing data field');
    }
    return MySponsorshipsResponse.fromJson(data);
  }

  /// Recupere les infos du parrain du driver connecte.
  Future<SponsorInfo?> getMySponsor() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sponsorships/me/sponsor',
    );

    final data = response.data?['data'];
    if (data == null) return null;
    return SponsorInfo.fromJson(data as Map<String, dynamic>);
  }
}

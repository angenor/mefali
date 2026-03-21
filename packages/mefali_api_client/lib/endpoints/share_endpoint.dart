import 'package:dio/dio.dart';
import 'package:mefali_core/models/share_data.dart';

class ShareEndpoint {
  const ShareEndpoint(this._dio);
  final Dio _dio;

  Future<ReferralCodeResponse> getReferralCode() async {
    final response = await _dio.get('/api/v1/users/me/referral');
    return ReferralCodeResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ShareMetadata> getShareMetadata(String merchantId) async {
    final response = await _dio.get('/api/v1/share/restaurant/$merchantId');
    return ShareMetadata.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}

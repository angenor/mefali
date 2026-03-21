import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/models/share_data.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/share_endpoint.dart';

final referralCodeProvider =
    FutureProvider.autoDispose<ReferralCodeResponse>((ref) async {
  final endpoint = ShareEndpoint(ref.watch(dioProvider));
  return endpoint.getReferralCode();
});

final shareMetadataProvider = FutureProvider.autoDispose
    .family<ShareMetadata, String>((ref, merchantId) async {
  final endpoint = ShareEndpoint(ref.watch(dioProvider));
  return endpoint.getShareMetadata(merchantId);
});

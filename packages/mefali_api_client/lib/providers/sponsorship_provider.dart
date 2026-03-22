import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/sponsorship_endpoint.dart';

/// Provider pour recuperer les filleuls du driver connecte.
final mySponsorshipsProvider =
    FutureProvider.autoDispose<MySponsorshipsResponse>((ref) async {
  final endpoint = SponsorshipEndpoint(ref.watch(dioProvider));
  return endpoint.getMySponsored();
});

/// Provider pour recuperer le parrain du driver connecte.
final mySponsorProvider =
    FutureProvider.autoDispose<SponsorInfo?>((ref) async {
  final endpoint = SponsorshipEndpoint(ref.watch(dioProvider));
  return endpoint.getMySponsor();
});

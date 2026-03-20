import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/wallet_endpoint.dart';

/// Provider pour le wallet du livreur (solde + transactions recentes).
final walletProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final endpoint = WalletEndpoint(ref.watch(dioProvider));
  return endpoint.getWallet();
});

import 'package:dio/dio.dart';

/// Client pour les endpoints wallet.
class WalletEndpoint {
  const WalletEndpoint(this._dio);

  final Dio _dio;

  /// Recuperer le wallet et les transactions recentes.
  Future<Map<String, dynamic>> getWallet() async {
    final response = await _dio.get<Map<String, dynamic>>('/wallets/me');
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Demander un retrait vers mobile money.
  /// Retourne la transaction creee.
  Future<Map<String, dynamic>> withdraw(int amount, String phoneNumber) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/wallets/withdraw',
      data: {'amount': amount, 'phone_number': phoneNumber},
    );
    return response.data!['data'] as Map<String, dynamic>;
  }
}

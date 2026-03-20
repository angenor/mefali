import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ecran intermediaire apres retour de CinetPay (story 4.5).
/// Poll le statut de la commande toutes les 3s pendant 60s max.
/// Succes (escrow_held) -> OrderTrackingScreen.
/// Echec/timeout -> affiche erreur + boutons Reessayer / Payer en cash.
class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  Timer? _pollTimer;
  int _pollCount = 0;
  static const _maxPolls = 20; // 20 * 3s = 60s
  static const _pollInterval = Duration(seconds: 3);

  bool _isPolling = true;
  bool _paymentFailed = false;
  bool _isRetrying = false;
  Order? _order;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel(); // C2: cancel existing timer before creating new one
    _pollCount = 0;
    _isPolling = true;
    _paymentFailed = false;
    if (mounted) setState(() {});

    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkPaymentStatus());
  }

  Future<void> _checkPaymentStatus() async {
    _pollCount++;
    try {
      final endpoint = OrderEndpoint(ref.read(dioProvider));
      final order = await endpoint.getOrderById(widget.orderId);
      _order = order;

      if (order.paymentStatus == 'escrow_held') {
        _pollTimer?.cancel();
        if (!mounted) return;
        // C3: clear cart only after payment confirmed
        ref.read(cartProvider.notifier).clear();
        ref.invalidate(customerOrdersProvider);
        context.go('/order/tracking/${widget.orderId}');
        return;
      }

      if (order.paymentStatus == 'refunded' ||
          order.paymentStatus == 'failed') {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isPolling = false;
          _paymentFailed = true;
        });
        return;
      }

      // Timeout after max polls
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isPolling = false;
          _paymentFailed = true;
        });
      }
    } on Exception catch (e) {
      // M1: log polling errors instead of silently ignoring
      debugPrint('Payment status poll #$_pollCount failed: $e');
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isPolling = false;
          _paymentFailed = true;
        });
      }
    }
  }

  /// M4: retry payment via backend, re-open CinetPay, then resume polling.
  Future<void> _retryPayment() async {
    setState(() => _isRetrying = true);
    try {
      final endpoint = OrderEndpoint(ref.read(dioProvider));
      final paymentUrl = await endpoint.retryPayment(widget.orderId);

      if (paymentUrl != null && mounted) {
        final uri = Uri.parse(paymentUrl);
        if (uri.scheme == 'https') {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (!mounted) return;
      setState(() => _isRetrying = false);
      _startPolling();
    } on Exception catch (e) {
      debugPrint('Payment retry failed: $e');
      if (!mounted) return;
      setState(() => _isRetrying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de relancer le paiement. ${e.toString().replaceAll("Exception: ", "")}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _isPolling ? _buildPollingState(colorScheme, textTheme)
                : _paymentFailed ? _buildFailedState(colorScheme, textTheme)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildPollingState(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification du paiement\nen cours...',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Commande #${widget.orderId.substring(0, 8)}',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (_order != null) ...[
          const SizedBox(height: 4),
          Text(
            'Total : ${formatFcfa(_order!.total)}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFailedState(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: colorScheme.error,
        ),
        const SizedBox(height: 24),
        Text(
          'Paiement echoue',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Verifiez votre solde et reessayez.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isRetrying ? null : _retryPayment,
            child: _isRetrying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('REESSAYER'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // H2: navigate to home — user can re-order with COD
              context.go('/');
            },
            child: const Text('RETOUR A L\'ACCUEIL'),
          ),
        ),
      ],
    );
  }
}

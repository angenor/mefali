import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_design/mefali_design.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pending_accept_queue.dart';

/// Ecran du protocole client absent (story 5.7).
/// Timer 10 minutes, appel client, resolution (COD vs prepaid).
class ClientAbsentScreen extends ConsumerStatefulWidget {
  const ClientAbsentScreen({
    required this.deliveryId,
    required this.orderId,
    required this.paymentType,
    required this.deliveryFee,
    this.customerPhone,
    super.key,
  });

  final String deliveryId;
  final String orderId;
  final String paymentType;
  final int deliveryFee;
  final String? customerPhone;

  @override
  ConsumerState<ClientAbsentScreen> createState() => _ClientAbsentScreenState();
}

class _ClientAbsentScreenState extends ConsumerState<ClientAbsentScreen> {
  static const _timerDuration = 600; // 10 minutes in seconds
  int _remainingSeconds = _timerDuration;
  Timer? _timer;
  bool _isLoading = false;
  bool _timerExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _timerExpired = true;
          _timer?.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _callClient() async {
    if (widget.customerPhone == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numero du client non disponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:${widget.customerPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Client est arrive pendant le timer — retour au flow normal (AC #3).
  /// Pop back to collection_navigation_screen where driver can tap LIVRE.
  void _handleClientArrived() {
    if (mounted) {
      context.pop();
    }
  }

  /// Resoudre le protocole apres expiration du timer.
  Future<void> _handleResolve(String resolution) async {
    setState(() => _isLoading = true);

    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de recuperer votre position GPS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final endpoint = DeliveryEndpoint(ref.read(dioProvider));
        final result = await endpoint.resolveClientAbsent(
          widget.deliveryId,
          resolution,
          pos.latitude,
          pos.longitude,
        );

        if (mounted) {
          final earnings =
              (result['driver_earnings_fcfa'] as num?)?.toInt() ?? 0;
          WalletCreditFeedback.show(context, earnings);

          setState(() => _isLoading = false);

          await Future<void>.delayed(const Duration(milliseconds: 2500));
          if (mounted) context.go('/home');
        }
      } on DioException catch (e) {
        setState(() => _isLoading = false);
        if (e.response?.statusCode == 409 && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Deja resolu'),
              content: const Text('Ce protocole client absent a deja ete resolu.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (mounted) context.go('/home');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Offline: queue resolve_absent
      await PendingAcceptQueue.instance.enqueue(
        widget.deliveryId,
        widget.orderId,
        action: 'resolve_absent',
        missionData: {
          'resolution': resolution,
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hors connexion — resolution en attente de sync'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/home');
      }
    }
  }

  Future<bool> _checkOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CLIENT ABSENT'),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Timer countdown
              Text(
                _formattedTime,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _timerExpired ? const Color(0xFFF44336) : null,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                _timerExpired
                    ? 'Le delai est expire. Choisissez une action.'
                    : 'Le client n\'est pas a l\'adresse.\nAttendez ou appelez-le.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),

              const Spacer(),

              // Actions pendant le timer
              if (!_timerExpired) ...[
                // Appeler le client
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _callClient,
                    icon: const Icon(Icons.phone),
                    label: const Text('APPELER LE CLIENT'),
                  ),
                ),
                const SizedBox(height: 12),
                // Le client est arrive
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _handleClientArrived,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: const Text(
                      'LE CLIENT EST ARRIVE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // Resolution buttons (after timer expires)
              if (_timerExpired) ...[
                if (widget.paymentType == 'cod') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed:
                          _isLoading ? null : () => _handleResolve('returned_to_restaurant'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5D4037),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'RETOURNER AU RESTAURANT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed:
                        _isLoading ? null : () => _handleResolve('returned_to_base'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.paymentType == 'cod'
                                ? 'RETOURNER A LA BASE'
                                : 'RETOURNER A LA BASE MEFALI',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

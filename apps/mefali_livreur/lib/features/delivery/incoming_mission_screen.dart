import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'pending_accept_queue.dart';

/// Ecran plein ecran pour afficher une mission de livraison entrante.
/// Le livreur voit le DeliveryMissionCard avec auto-dismiss 30s.
class IncomingMissionScreen extends ConsumerWidget {
  const IncomingMissionScreen({this.missionData, super.key});

  /// Mission data from push notification payload (optional).
  /// If null, loads from the pending mission API endpoint.
  final Map<String, dynamic>? missionData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If mission data is provided via push payload, use it directly
    if (missionData != null) {
      final mission = _missionFromPushData(missionData!);
      return _buildMissionView(context, mission);
    }

    // Otherwise load from API
    final asyncMission = ref.watch(pendingMissionProvider);
    return asyncMission.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
      data: (mission) {
        if (mission == null) {
          // No pending mission — go back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/home');
          });
          return const Scaffold(
            body: Center(child: Text('Aucune mission en attente')),
          );
        }
        return _buildMissionView(context, mission);
      },
    );
  }

  Widget _buildMissionView(BuildContext context, DeliveryMission mission) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle course'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: DeliveryMissionCard(
            mission: mission,
            onAccept: () => _handleAccept(context, mission),
            onDismiss: () {
              if (context.mounted) context.go('/home');
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    DeliveryMission mission,
  ) async {
    // Check connectivity (use example.com — universally resolvable, unlike
    // google.com which some African networks may block or throttle)
    bool isOnline;
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      isOnline = false;
    }

    if (isOnline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission acceptee !'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        // Full accept API call will be in story 5.3
        context.go('/home');
      }
    } else {
      // Offline: queue for sync (full mission data for recovery)
      await PendingAcceptQueue.instance.enqueue(
        mission.deliveryId,
        mission.orderId,
        mission.toJson(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hors connexion — acceptation en attente de sync'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 4),
          ),
        );
        context.go('/home');
      }
    }
  }

  /// Parse a DeliveryMission from push notification or deep link data payload.
  DeliveryMission _missionFromPushData(Map<String, dynamic> data) {
    return DeliveryMission(
      deliveryId: data['delivery_id']?.toString() ?? '',
      orderId: data['order_id']?.toString() ?? '',
      merchantName: data['merchant_name']?.toString() ?? 'Restaurant',
      merchantAddress: data['merchant_address']?.toString(),
      deliveryAddress: data['delivery_address']?.toString(),
      deliveryLat: double.tryParse(data['delivery_lat']?.toString() ?? ''),
      deliveryLng: double.tryParse(data['delivery_lng']?.toString() ?? ''),
      estimatedDistanceM:
          int.tryParse(data['estimated_distance_m']?.toString() ?? ''),
      deliveryFee: int.tryParse(data['delivery_fee']?.toString() ?? '') ?? 0,
      itemsSummary: data['items_summary']?.toString() ?? '',
      paymentType: data['payment_type']?.toString(),
      orderTotal: int.tryParse(data['order_total']?.toString() ?? ''),
      createdAt: data['created_at']?.toString() ?? '',
    );
  }
}

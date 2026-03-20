import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'pending_accept_queue.dart';

/// Ecran plein ecran pour afficher une mission de livraison entrante.
/// Le livreur voit le DeliveryMissionCard avec auto-dismiss 30s.
class IncomingMissionScreen extends ConsumerStatefulWidget {
  const IncomingMissionScreen({this.missionData, super.key});

  final Map<String, dynamic>? missionData;

  @override
  ConsumerState<IncomingMissionScreen> createState() =>
      _IncomingMissionScreenState();
}

class _IncomingMissionScreenState extends ConsumerState<IncomingMissionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.missionData != null) {
      final mission = _missionFromPushData(widget.missionData!);
      return _buildMissionView(context, mission);
    }

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
            isLoading: _isLoading,
            onAccept: () => _handleAccept(context, mission),
            onRefuse: () => _showRefuseDialog(context, mission),
            onDismiss: () => _handleTimeout(context, mission),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleAccept(
    BuildContext context,
    DeliveryMission mission,
  ) async {
    setState(() => _isLoading = true);
    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final endpoint = DeliveryEndpoint(ref.read(dioProvider));
        final acceptedMission = await endpoint.acceptMission(mission.deliveryId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mission acceptee !'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          context.go('/delivery/collection-navigation', extra: acceptedMission);
        }
      } on DioException catch (e) {
        setState(() => _isLoading = false);
        if (e.response?.statusCode == 409 && context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Mission indisponible'),
              content: const Text('Mission prise par un autre livreur.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (context.mounted) context.go('/home');
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
      await PendingAcceptQueue.instance.enqueue(
        mission.deliveryId,
        mission.orderId,
        missionData: mission.toJson(),
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

  Future<void> _showRefuseDialog(
    BuildContext context,
    DeliveryMission mission,
  ) async {
    final reasons = {
      'too_far': 'Trop loin',
      'not_enough_time': 'Pas assez de temps',
      'wrong_direction': 'Mauvaise direction',
      'vehicle_issue': 'Probleme vehicule',
      'other': 'Autre raison',
    };

    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Pourquoi refusez-vous ?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: reasons.entries.map((entry) {
              return ListTile(
                leading: Radio<String>(
                  value: entry.key,
                  groupValue: selectedReason,
                  onChanged: (v) => setDialogState(() => selectedReason = v),
                ),
                title: Text(entry.value),
                onTap: () => setDialogState(() => selectedReason = entry.key),
              );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ANNULER'),
            ),
            FilledButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('CONFIRMER REFUS'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedReason != null && context.mounted) {
      await _handleRefuse(context, mission, selectedReason!);
    }
  }

  Future<void> _handleRefuse(
    BuildContext context,
    DeliveryMission mission,
    String reason,
  ) async {
    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final endpoint = DeliveryEndpoint(ref.read(dioProvider));
        await endpoint.refuseMission(mission.deliveryId, reason);
      } on DioException catch (e) {
        if (e.response?.statusCode == 409 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mission deja prise par un autre livreur'),
              backgroundColor: Color(0xFFFF9800),
            ),
          );
        }
      }
    } else {
      await PendingAcceptQueue.instance.enqueue(
        mission.deliveryId,
        mission.orderId,
        missionData: mission.toJson(),
        action: 'refuse',
        reason: reason,
      );
    }

    if (context.mounted) context.go('/home');
  }

  Future<void> _handleTimeout(
    BuildContext context,
    DeliveryMission mission,
  ) async {
    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final endpoint = DeliveryEndpoint(ref.read(dioProvider));
        await endpoint.refuseMission(mission.deliveryId, 'timeout');
      } on DioException catch (_) {
        // Best effort
      }
    } else {
      await PendingAcceptQueue.instance.enqueue(
        mission.deliveryId,
        mission.orderId,
        missionData: mission.toJson(),
        action: 'refuse',
        reason: 'timeout',
      );
    }

    if (context.mounted) context.go('/home');
  }

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

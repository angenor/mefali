import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import '../delivery/pending_accept_queue.dart';
import '../notification/fcm_token_provider.dart';
import '../notification/push_notification_handler.dart';

/// Ecran d'accueil livreur avec toggle disponibilite et acces wallet.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    PushNotificationHandler.instance.onMissionReceived((data) {
      if (mounted) {
        context.push('/delivery/incoming-mission', extra: data);
      }
    });
  }

  @override
  void dispose() {
    PushNotificationHandler.instance.removeMissionListener();
    super.dispose();
  }

  Future<void> _toggleAvailability(bool value) async {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);

    if (isOnline) {
      await ref.read(driverAvailabilityProvider.notifier).toggle(value);
    } else {
      // Queue for offline sync
      await PendingAcceptQueue.instance.enqueue(
        'availability',
        '',
        action: 'toggle_availability',
        missionData: {'is_available': value},
      );
      // Update local state optimistically
      ref.read(driverAvailabilityProvider.notifier).toggle(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hors ligne — statut mis a jour au retour de connexion'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Livreur';
    final status = authState.user?.status;
    final isPendingKyc = status == UserStatus.pendingKyc;
    final availability = ref.watch(driverAvailabilityProvider);

    // Register FCM token with backend (non-blocking)
    ref.watch(fcmTokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('mefali Livreur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Wallet',
            onPressed: () => context.push('/wallet'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Bienvenue $userName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              if (isPendingKyc) ...[
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.hourglass_top,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'En attente de validation KYC',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Votre compte est en cours de verification. '
                          'Un agent terrain validera vos documents prochainement. '
                          'Vous pourrez recevoir des missions une fois valide.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Availability toggle card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        availability.when(
                          data: (isAvailable) => Icon(
                            isAvailable ? Icons.circle : Icons.pause_circle_filled,
                            color: isAvailable ? Colors.green : Colors.orange,
                            size: 28,
                          ),
                          loading: () => const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: availability.when(
                            data: (isAvailable) => Text(
                              isAvailable ? 'Actif — vous recevez des missions' : 'En pause',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                            ),
                            loading: () => Text(
                              'Chargement...',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            error: (_, __) => Text(
                              'Erreur de connexion',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.red,
                                  ),
                            ),
                          ),
                        ),
                        availability.when(
                          data: (isAvailable) => Switch(
                            value: isAvailable,
                            onChanged: _toggleAvailability,
                            activeColor: Colors.green,
                          ),
                          loading: () => const Switch(value: false, onChanged: null),
                          error: (_, __) => IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            onPressed: () => ref.read(driverAvailabilityProvider.notifier).refresh(),
                            tooltip: 'Reessayer',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

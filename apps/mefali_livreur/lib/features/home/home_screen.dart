import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import '../notification/fcm_token_provider.dart';
import '../notification/push_notification_handler.dart';

/// Ecran d'accueil livreur — placeholder en attente de validation KYC.
/// Initialise le token FCM et ecoute les missions entrantes.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for incoming delivery missions from push notifications
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Livreur';
    final status = authState.user?.status;
    final isPendingKyc = status == UserStatus.pendingKyc;

    // Register FCM token with backend (non-blocking)
    ref.watch(fcmTokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('mefali Livreur'),
        actions: [
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
              const SizedBox(height: 32),
              Text(
                'Bienvenue $userName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'En attente de validation KYC',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
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
              ] else
                Text(
                  'Votre compte est actif.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

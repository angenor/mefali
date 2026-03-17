import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Etape 4: Paiement — affichage informatif (wallet auto-cree).
class Step4PaymentScreen extends ConsumerWidget {
  const Step4PaymentScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletCreated = ref
            .watch(onboardingProvider)
            .whenOrNull(data: (s) => s.walletCreated) ??
        false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Etape 4/5 — Paiement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    walletCreated ? Icons.check_circle : Icons.account_balance_wallet,
                    size: 64,
                    color: walletCreated ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    walletCreated
                        ? 'Wallet cree avec succes !'
                        : 'Le wallet sera cree automatiquement.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Les gains des commandes seront credites dans le wallet du marchand. '
                    'Le retrait se fait via Mobile Money.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
}

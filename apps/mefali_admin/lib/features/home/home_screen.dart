import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Dashboard agent simplifie — liste onboardings en cours + bouton nouveau.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress = ref.watch(inProgressMerchantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('mefali Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.add_business),
              label: const Text('Nouveau marchand'),
              onPressed: () => context.push('/onboarding/new'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.badge),
              label: const Text('KYC Livreurs'),
              onPressed: () => context.push('/kyc'),
            ),
            const SizedBox(height: 24),
            Text(
              'Onboardings en cours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: inProgress.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (merchants) {
                  if (merchants.isEmpty) {
                    return const Center(
                      child: Text('Aucun onboarding en cours'),
                    );
                  }
                  return ListView.builder(
                    itemCount: merchants.length,
                    itemBuilder: (context, index) {
                      final m = merchants[index];
                      return _MerchantCard(merchant: m);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.merchant});

  final Merchant merchant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.store),
        title: Text(merchant.name),
        subtitle: Text('Etape ${merchant.onboardingStep}/5'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/onboarding/${merchant.id}'),
      ),
    );
  }
}

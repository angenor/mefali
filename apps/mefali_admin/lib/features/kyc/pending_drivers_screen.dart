import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Ecran listant les livreurs en attente de verification KYC.
class PendingDriversScreen extends ConsumerWidget {
  const PendingDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingDriversProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Livreurs')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erreur: $e'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(pendingDriversProvider),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('Aucun livreur en attente de KYC'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user.name ?? 'Sans nom'),
                  subtitle: Text(user.phone),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/kyc/${user.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

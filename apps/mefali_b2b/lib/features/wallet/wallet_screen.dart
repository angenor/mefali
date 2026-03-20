import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Ecran wallet du marchand — solde et historique des transactions.
/// Pas de retrait (story 6-2).
class MerchantWalletScreen extends ConsumerWidget {
  const MerchantWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return walletAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $e', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(walletProvider),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
      data: (data) {
        final wallet = data['wallet'] as Map<String, dynamic>;
        final balance = wallet['balance'] as int? ?? 0;
        final transactions =
            (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(walletProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceCard(balance: balance),
              const SizedBox(height: 24),
              Text(
                'Historique des paiements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune transaction\n\nVos revenus apparaitront ici apres votre premiere livraison completee.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...transactions.map((tx) => _TransactionTile(tx: tx)),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final fcfa = balance ~/ 100;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Solde disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$fcfa FCFA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final type = tx['transaction_type'] as String? ?? '';
    final amount = tx['amount'] as int? ?? 0;
    final amountFcfa = amount ~/ 100;
    final reference = tx['reference'] as String? ?? '';
    final description = tx['description'] as String? ?? '';
    final createdAt = tx['created_at'] as String? ?? '';

    final isCredit = type == 'credit' || type == 'refund';
    final icon = switch (type) {
      'credit' => Icons.arrow_downward,
      'withdrawal' => Icons.arrow_upward,
      'debit' => Icons.arrow_upward,
      'refund' => Icons.replay,
      _ => Icons.swap_horiz,
    };
    final color = isCredit ? Colors.green : Colors.red;
    final prefix = isCredit ? '+' : '-';

    // Show order short ID if reference is order:uuid
    final subtitle = reference.startsWith('order:')
        ? 'Commande #${reference.substring(6, 14)}'
        : description;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(description.isNotEmpty ? description : type),
      subtitle: Text(
        '${subtitle.isNotEmpty ? '$subtitle — ' : ''}${_formatDate(createdAt)}',
      ),
      trailing: Text(
        '$prefix$amountFcfa FCFA',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

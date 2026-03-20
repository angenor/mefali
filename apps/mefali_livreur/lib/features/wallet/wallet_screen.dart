import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Ecran wallet du livreur — solde, historique des transactions, retrait.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Wallet')),
      body: walletAsync.when(
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
                _BalanceCard(balance: balance, context: context),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: balance > 0
                        ? () => _showWithdrawSheet(context, ref, balance)
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Retirer vers Mobile Money'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Historique',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Aucune transaction pour le moment.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...transactions.map((tx) => _TransactionTile(tx: tx)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, WidgetRef ref, int balance) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _WithdrawSheet(balance: balance, ref: ref),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.context});

  final int balance;
  final BuildContext context;

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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(description.isNotEmpty ? description : type),
      subtitle: Text(_formatDate(createdAt)),
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

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.balance, required this.ref});

  final int balance;
  final WidgetRef ref;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill phone from auth state
    final authState = widget.ref.read(authProvider);
    _phoneController.text = authState.user?.phone ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amountFcfa = int.tryParse(_amountController.text) ?? 0;
    final amountCentimes = amountFcfa * 100;

    setState(() => _loading = true);

    try {
      final dio = widget.ref.read(dioProvider);
      final endpoint = WalletEndpoint(dio);
      await endpoint.withdraw(amountCentimes, _phoneController.text);

      if (mounted) {
        widget.ref.invalidate(walletProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retrait de $amountFcfa FCFA initie avec succes !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 409) {
        String? message;
        final data = e.response?.data;
        if (data is Map) {
          final error = data['error'];
          if (error is Map) {
            message = error['message'] as String?;
          }
        }
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Retrait impossible'),
            content: Text(message ?? 'Verifiez le montant et reessayez.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.type == DioExceptionType.connectionTimeout ||
                      e.type == DioExceptionType.receiveTimeout
                  ? 'Delai de connexion depasse. Reessayez.'
                  : 'Erreur reseau. Verifiez votre connexion.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxFcfa = widget.balance ~/ 100;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Retirer vers Mobile Money',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Solde: $maxFcfa FCFA'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final amount = int.tryParse(v ?? '') ?? 0;
                if (amount <= 0) return 'Montant invalide';
                if (amount * 100 > widget.balance) return 'Solde insuffisant';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numero Mobile Money',
                border: OutlineInputBorder(),
                hintText: '+225XXXXXXXXXX',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Numero requis';
                final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
                if (!RegExp(r'^(\+225)?[0-9]{10}$').hasMatch(cleaned)) {
                  return 'Format invalide (ex: +2250700000000)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmer le retrait'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

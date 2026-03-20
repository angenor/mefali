import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Ecran wallet du marchand — solde, historique et retrait mobile money.
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
              _BalanceCard(
                balance: balance,
                onWithdraw: balance > 0
                    ? () => _showWithdrawSheet(context, ref, balance)
                    : null,
              ),
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

  void _showWithdrawSheet(BuildContext context, WidgetRef ref, int balance) {
    final userPhone = ref.read(authProvider).user?.phone ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _WithdrawSheet(
          balance: balance,
          initialPhone: userPhone,
          onSubmit: (amount, phone) async {
            final endpoint = WalletEndpoint(ref.read(dioProvider));
            await endpoint.withdraw(amount, phone);
            ref.invalidate(walletProvider);
          },
        ),
      ),
    );
  }
}

/// Format centimes to "X XXX" FCFA string with thousands separator.
String _formatAmount(int centimes) {
  final fcfa = centimes ~/ 100;
  final s = fcfa.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.writeCharCode(s.codeUnitAt(i));
  }
  return buf.toString();
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, this.onWithdraw});

  final int balance;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
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
              '${_formatAmount(balance)} FCFA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onWithdraw,
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Retirer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({
    required this.balance,
    required this.initialPhone,
    required this.onSubmit,
  });

  final int balance;
  final String initialPhone;
  final Future<void> Function(int amountCentimes, String phone) onSubmit;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _balanceFcfa => widget.balance ~/ 100;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amountFcfa = int.parse(_amountController.text);
    final amountCentimes = amountFcfa * 100;
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(amountCentimes, phone);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retrait de ${_formatAmount(amountCentimes)} FCFA effectue'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Echec du retrait. Veuillez reessayer.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Retirer vers mobile money',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Solde disponible : ${_formatAmount(widget.balance)} FCFA',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez un montant';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Le montant doit etre positif';
                  }
                  if (amount > _balanceFcfa) {
                    return 'Solde insuffisant';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numero mobile money',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+2250700000000',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Entrez un numero de telephone';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmer le retrait'),
              ),
            ],
          ),
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
    final subtitle = reference.startsWith('order:') && reference.length >= 14
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
        '$prefix${_formatAmount(amount)} FCFA',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

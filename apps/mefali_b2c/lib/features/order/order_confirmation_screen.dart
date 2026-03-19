import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ecran de confirmation apres creation de commande (story 4.3).
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    required this.order,
    super.key,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success icon
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Commande confirmee !',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Votre commande est en cours de preparation',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Order summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Commande',
                        value: '#${order.id.substring(0, 8).toUpperCase()}',
                      ),
                      const Divider(height: 16),
                      if (order.items.isNotEmpty)
                        for (final item in order.items)
                          _SummaryRow(
                            label:
                                '${item.productName ?? 'Article'} x${item.quantity}',
                            value: formatFcfa(item.lineTotal),
                          ),
                      if (order.items.isNotEmpty) const Divider(height: 16),
                      _SummaryRow(
                        label: 'Livraison',
                        value: formatFcfa(order.deliveryFee),
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: 'Total',
                        value: formatFcfa(order.total),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Return home button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Retour a l\'accueil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = isBold
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

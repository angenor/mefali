import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_design/mefali_design.dart';

/// Ecran liste des commandes actives du marchand.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(merchantOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _EmptyOrders();
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(merchantOrdersProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                onAccept: () => _acceptOrder(context, ref, order.id),
                onReject: () => _showRejectDialog(context, ref, order.id),
                onReady: () => _markReady(context, ref, order.id),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(merchantOrdersProvider),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptOrder(BuildContext context, WidgetRef ref, String orderId) {
    // Feedback haptique
    HapticFeedback.mediumImpact();

    ref.read(orderActionProvider.notifier).acceptOrder(orderId).then((_) {
      if (!context.mounted) return;
      final state = ref.read(orderActionProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${state.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(days: 1),
            showCloseIcon: true,
            closeIconColor: Colors.white,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande acceptee'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _markReady(BuildContext context, WidgetRef ref, String orderId) {
    HapticFeedback.mediumImpact();

    ref.read(orderActionProvider.notifier).markReady(orderId).then((_) {
      if (!context.mounted) return;
      final state = ref.read(orderActionProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${state.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(days: 1),
            showCloseIcon: true,
            closeIconColor: Colors.white,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande marquee prete'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) {
    String? selectedReason;
    final customController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Refuser la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final reason in _rejectReasons)
                ListTile(
                  leading: Icon(
                    selectedReason == reason
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedReason == reason
                        ? Theme.of(ctx).colorScheme.primary
                        : null,
                  ),
                  title: Text(reason),
                  onTap: () => setState(() {
                    selectedReason = reason;
                    customController.clear();
                  }),
                ),
              ListTile(
                leading: Icon(
                  selectedReason == '_custom'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedReason == '_custom'
                      ? Theme.of(ctx).colorScheme.primary
                      : null,
                ),
                title: const Text('Autre raison'),
                onTap: () => setState(() => selectedReason = '_custom'),
              ),
              if (selectedReason == '_custom')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: customController,
                    decoration: const InputDecoration(
                      hintText: 'Saisissez la raison...',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 500,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final reason = selectedReason == '_custom'
                    ? customController.text.trim()
                    : selectedReason;
                if (reason == null || reason.isEmpty) return;

                Navigator.of(ctx).pop();
                _rejectOrder(context, ref, orderId, reason);
              },
              child: const Text('Refuser'),
            ),
          ],
        ),
      ),
    );
  }

  void _rejectOrder(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    String reason,
  ) {
    HapticFeedback.mediumImpact();

    ref.read(orderActionProvider.notifier).rejectOrder(orderId, reason).then((_) {
      if (!context.mounted) return;
      final state = ref.read(orderActionProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${state.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(days: 1),
            showCloseIcon: true,
            closeIconColor: Colors.white,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande refusee'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }
}

const _rejectReasons = [
  'Produit en rupture de stock',
  'Fermeture anticipee',
  'Trop de commandes en cours',
];

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande en attente',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

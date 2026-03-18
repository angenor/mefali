import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Carte de commande pour le marchand B2B.
///
/// Affiche les details de la commande et les actions contextuelles
/// selon le statut (accepter/refuser pour nouvelle, prete pour en preparation).
class OrderCard extends StatelessWidget {
  const OrderCard({
    required this.order,
    this.onAccept,
    this.onReject,
    this.onReady,
    super.key,
  });

  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = order.status == OrderStatus.pending;

    return Card(
      elevation: isPending ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? const BorderSide(color: Color(0xFFFF9800), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: statut + timestamp
            _buildHeader(context),
            const SizedBox(height: 12),
            // Items list
            _buildItemsList(theme),
            const Divider(height: 24),
            // Total
            _buildTotal(theme),
            // Notes client
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotes(theme),
            ],
            // Actions
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(order.status.icon, color: order.status.color, size: 20),
        const SizedBox(width: 8),
        Text(
          order.status.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: order.status.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          _formatTime(order.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(ThemeData theme) {
    return Column(
      children: order.items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.productName ?? 'Produit',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    item.unitPriceFormatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTotal(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          order.totalFormatted,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.note,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              order.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return switch (order.status) {
      OrderStatus.pending => _buildPendingActions(context),
      OrderStatus.confirmed => _buildConfirmedActions(context),
      OrderStatus.ready => _buildReadyLabel(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildPendingActions(BuildContext context) {
    return Row(
      children: [
        // Refuser — petit bouton texte
        TextButton(
          onPressed: onReject,
          child: Text(
            'REFUSER',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        const Spacer(),
        // Accepter — gros bouton vert
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32),
            ),
            icon: const Icon(Icons.check),
            label: const Text(
              'ACCEPTER',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onReady,
        icon: const Icon(Icons.check_circle),
        label: const Text(
          'PRETE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReadyLabel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'En attente du livreur',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

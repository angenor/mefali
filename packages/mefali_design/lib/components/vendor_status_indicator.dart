import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Pastille coloree affichant le statut de disponibilite du marchand.
///
/// En mode [interactive] (B2B), le tap ouvre un bottom sheet de selection.
/// En mode read-only (B2C), il affiche simplement l'etat.
class VendorStatusIndicator extends StatelessWidget {
  const VendorStatusIndicator({
    required this.status,
    this.interactive = false,
    this.onStatusChanged,
    super.key,
  });

  final VendorStatus status;
  final bool interactive;
  final ValueChanged<VendorStatus>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final chip = InkWell(
      onTap: interactive ? () => _showStatusSheet(context) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 16, color: status.color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );

    // Ensure minimum 48dp touch target for AppBar placement.
    return SizedBox(
      height: 48,
      child: Center(child: chip),
    );
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _StatusSelectionSheet(
        currentStatus: status,
        onSelected: (selected) {
          Navigator.of(context).pop();
          onStatusChanged?.call(selected);
        },
      ),
    );
  }
}

/// Bottom sheet de selection de statut.
class _StatusSelectionSheet extends StatelessWidget {
  const _StatusSelectionSheet({
    required this.currentStatus,
    required this.onSelected,
  });

  final VendorStatus currentStatus;
  final ValueChanged<VendorStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    // Si auto_paused, seul bouton "Reactiver" (→ open).
    if (currentStatus == VendorStatus.autoPaused) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vous etes en pause automatique',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '3 commandes sans reponse',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onSelected(VendorStatus.open),
                  icon: Icon(VendorStatus.open.icon),
                  label: const Text('Reactiver'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Affiche les 3 options manuelles.
    final options = [
      VendorStatus.open,
      VendorStatus.overwhelmed,
      VendorStatus.closed,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Changer mon statut',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            for (final option in options)
              ListTile(
                leading: Icon(
                  option.icon,
                  color: currentStatus.validManualTransitions.contains(option)
                      ? option.color
                      : option.color.withValues(alpha: 0.3),
                ),
                title: Text(option.label),
                trailing: option == currentStatus
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                enabled: currentStatus.validManualTransitions.contains(option),
                onTap: currentStatus.validManualTransitions.contains(option)
                    ? () => onSelected(option)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

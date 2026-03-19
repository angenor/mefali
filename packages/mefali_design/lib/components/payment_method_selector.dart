import 'package:flutter/material.dart';

/// Selecteur de mode de paiement (story 4.4).
/// COD pre-selectionne, Mobile Money desactive.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selectedMethod,
    required this.onChanged,
    super.key,
  });

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Mode de paiement',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _PaymentOption(
          label: 'Cash a la livraison',
          isSelected: selectedMethod == 'cod',
          onTap: () => onChanged('cod'),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        _PaymentOption(
          label: 'Mobile Money',
          subtitle: 'Bientot disponible',
          isSelected: false,
          enabled: false,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.isSelected,
    required this.textTheme,
    required this.colorScheme,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final String? subtitle;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: enabled
                  ? (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)
                  : colorScheme.onSurfaceVariant.withAlpha(80),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: enabled
                          ? null
                          : colorScheme.onSurfaceVariant.withAlpha(120),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(100),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

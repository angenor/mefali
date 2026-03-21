import 'package:flutter/material.dart';

class ShareButton extends StatelessWidget {
  const ShareButton({
    super.key,
    required this.onPressed,
    this.label = 'Partager sur WhatsApp',
    this.useWhatsAppColor = false,
  });

  final VoidCallback onPressed;
  final String label;
  final bool useWhatsAppColor;

  static const _whatsAppGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    if (useWhatsAppColor) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.share, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _whatsAppGreen,
          side: const BorderSide(color: _whatsAppGreen),
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.share),
      tooltip: label,
    );
  }
}

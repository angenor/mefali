import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteFriendsCard extends StatelessWidget {
  const InviteFriendsCard({
    super.key,
    required this.referralCode,
    required this.onSharePressed,
  });

  final String referralCode;
  final VoidCallback onSharePressed;

  static const _whatsAppGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitez vos amis !',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Votre code : ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SelectableText(
                  referralCode,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copie !')),
                    );
                  },
                  tooltip: 'Copier le code',
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onSharePressed,
              icon: const Icon(Icons.share),
              label: const Text('Partager sur WhatsApp'),
              style: FilledButton.styleFrom(
                backgroundColor: _whatsAppGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

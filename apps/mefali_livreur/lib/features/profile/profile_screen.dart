import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import 'sponsorship_screen.dart';

/// Ecran Profil livreur — affiche nom, telephone, role, statut KYC, deconnexion.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final initial = (user.name ?? 'L').isNotEmpty
        ? (user.name ?? 'L')[0].toUpperCase()
        : 'L';
    final isPendingKyc = user.status == UserStatus.pendingKyc;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // KYC status badge
          Center(
            child: Chip(
              avatar: Icon(
                isPendingKyc ? Icons.hourglass_top : Icons.check_circle,
                size: 18,
                color: isPendingKyc ? Colors.orange : Colors.green,
              ),
              label: Text(isPendingKyc ? 'En attente KYC' : 'Actif'),
              backgroundColor: isPendingKyc
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileTile(
            icon: Icons.person,
            label: 'Nom',
            value: user.name ?? 'Non renseigne',
            onTap: () => context.push('/profile/edit-name'),
          ),
          _ProfileTile(
            icon: Icons.phone,
            label: 'Telephone',
            value: user.phone,
            onTap: () => context.push('/profile/change-phone'),
          ),
          _ProfileTile(icon: Icons.badge, label: 'Role', value: user.role.name),
          _ProfileTile(
            icon: Icons.group,
            label: 'Parrainage',
            value: 'Mes filleuls et mon parrain',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SponsorshipScreen(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () => _confirmLogout(context, ref),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Deconnexion'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vraiment vous deconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logoutAndRevoke();
            },
            child: const Text('Deconnecter'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ecran detail d'un compte utilisateur pour l'admin.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(adminUserDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail du compte')),
      body: asyncDetail.when(
        loading: () => _buildSkeleton(context),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(adminUserDetailProvider(userId)),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
        data: (detail) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(adminUserDetailProvider(userId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(detail: detail),
              const SizedBox(height: 16),
              _StatsRow(detail: detail),
              const SizedBox(height: 24),
              _StatusActions(
                detail: detail,
                onStatusChange: (newStatus, reason) =>
                    _updateStatus(context, ref, detail, newStatus, reason),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 140, height: 18, color: color),
                          const SizedBox(height: 8),
                          Container(width: 100, height: 14, color: color),
                        ],
                      ),
                    ),
                    Container(width: 70, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))),
                  ],
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < 5; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(width: 100, height: 12, color: color),
                        const SizedBox(width: 16),
                        Container(width: 120, height: 12, color: color),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(4, (_) => Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(height: 4),
                    Container(width: 30, height: 16, color: color),
                    const SizedBox(height: 4),
                    Container(width: 50, height: 10, color: color),
                  ],
                ),
              ),
            ),
          )).expand((w) => [w, const SizedBox(width: 8)]).toList()..removeLast(),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    AdminUserDetail detail,
    String newStatus,
    String? reason,
  ) async {
    try {
      final endpoint = ref.read(adminEndpointProvider);
      await endpoint.updateUserStatus(
        detail.id,
        newStatus: newStatus,
        reason: reason,
      );
      ref.invalidate(adminUserDetailProvider(userId));
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statut mis a jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        String message = e.message ?? 'Erreur inconnue';
        if (e.response?.data is Map) {
          final errorData = (e.response!.data as Map)['error'];
          if (errorData is Map && errorData['message'] != null) {
            message = errorData['message'] as String;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _roleColor(detail.role),
                  child: Text(
                    (detail.name ?? detail.phone).substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.name ?? 'Sans nom',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(detail.phone,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
                _buildStatusBadge(detail.status),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Role', _roleLabel(detail.role)),
            _infoRow('Ville', detail.cityName ?? 'Non definie'),
            _infoRow('Code parrainage', detail.referralCode),
            _infoRow('Inscrit le', _formatDate(detail.createdAt)),
            _infoRow('Mis a jour', _formatDate(detail.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    final (label, color) = switch (status) {
      UserStatus.active => ('Actif', Colors.green),
      UserStatus.pendingKyc => ('KYC en attente', Colors.orange),
      UserStatus.suspended => ('Suspendu', Colors.red),
      UserStatus.deactivated => ('Desactive', Colors.grey),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color)),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.client => Colors.blue,
      UserRole.merchant => Colors.orange,
      UserRole.driver => Colors.green,
      UserRole.agent => Colors.purple,
      UserRole.admin => Colors.red,
    };
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.client => 'Client',
      UserRole.merchant => 'Marchand',
      UserRole.driver => 'Livreur',
      UserRole.agent => 'Agent terrain',
      UserRole.admin => 'Administrateur',
    };
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    return '$d/$m/$y';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Commandes',
          value: detail.totalOrders.toString(),
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Completion',
          value: '${detail.completionRate.toStringAsFixed(0)}%',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Litiges',
          value: detail.disputesFiled.toString(),
          icon: Icons.report_problem,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Note',
          value: detail.avgRating > 0
              ? detail.avgRating.toStringAsFixed(1)
              : '-',
          icon: Icons.star,
          color: Colors.amber,
        ),
      ].map((w) => Expanded(child: w)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.detail,
    required this.onStatusChange,
  });

  final AdminUserDetail detail;
  final Future<void> Function(String newStatus, String? reason) onStatusChange;

  @override
  Widget build(BuildContext context) {
    // Admins cannot be modified
    if (detail.role == UserRole.admin) {
      return const SizedBox.shrink();
    }

    final actions = <Widget>[];

    if (detail.status == UserStatus.active) {
      actions.add(
        FilledButton.tonal(
          onPressed: () => _confirmAction(
            context,
            'Suspendre ce compte ?',
            'L\'utilisateur ne pourra plus se connecter.',
            'suspended',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.withValues(alpha: 0.2),
            foregroundColor: Colors.orange[800],
          ),
          child: const Text('Suspendre'),
        ),
      );
      actions.add(const SizedBox(width: 8));
      actions.add(
        FilledButton.tonal(
          onPressed: () => _confirmAction(
            context,
            'Desactiver ce compte ?',
            'Le compte sera desactive definitivement.',
            'deactivated',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.2),
            foregroundColor: Colors.red[800],
          ),
          child: const Text('Desactiver'),
        ),
      );
    }

    if (detail.status == UserStatus.suspended) {
      actions.add(
        FilledButton(
          onPressed: () => _confirmAction(
            context,
            'Reactiver ce compte ?',
            'L\'utilisateur pourra se reconnecter.',
            'active',
          ),
          child: const Text('Reactiver'),
        ),
      );
      actions.add(const SizedBox(width: 8));
      actions.add(
        FilledButton.tonal(
          onPressed: () => _confirmAction(
            context,
            'Desactiver ce compte ?',
            'Le compte sera desactive definitivement.',
            'deactivated',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.2),
            foregroundColor: Colors.red[800],
          ),
          child: const Text('Desactiver'),
        ),
      );
    }

    if (detail.status == UserStatus.deactivated) {
      actions.add(
        FilledButton(
          onPressed: () => _confirmAction(
            context,
            'Reactiver ce compte ?',
            'L\'utilisateur pourra se reconnecter.',
            'active',
          ),
          child: const Text('Reactiver'),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: actions),
      ],
    );
  }

  Future<void> _confirmAction(
    BuildContext context,
    String title,
    String message,
    String newStatus,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      await onStatusChange(newStatus, reason.isEmpty ? null : reason);
    }
    reasonController.dispose();
  }
}

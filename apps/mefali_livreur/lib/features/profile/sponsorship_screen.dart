import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ecran Parrainage — affiche les filleuls du livreur et son parrain.
class SponsorshipScreen extends ConsumerWidget {
  const SponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsorshipsAsync = ref.watch(mySponsorshipsProvider);
    final sponsorAsync = ref.watch(mySponsorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Parrainage')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mySponsorshipsProvider);
          ref.invalidate(mySponsorProvider);
          await Future.wait([
            ref.read(mySponsorshipsProvider.future),
            ref.read(mySponsorProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section filleuls
            sponsorshipsAsync.when(
              data: (data) => _SponsoredSection(data: data),
              loading: () => const _ShimmerCard(),
              error: (e, _) => _ErrorCard(
                message: 'Erreur chargement filleuls',
                onRetry: () => ref.invalidate(mySponsorshipsProvider),
              ),
            ),
            const SizedBox(height: 24),
            // Section parrain
            sponsorAsync.when(
              data: (sponsor) => _SponsorSection(sponsor: sponsor),
              loading: () => const _ShimmerCard(),
              error: (e, _) => _ErrorCard(
                message: 'Erreur chargement parrain',
                onRetry: () => ref.invalidate(mySponsorProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsoredSection extends StatelessWidget {
  const _SponsoredSection({required this.data});

  final MySponsorshipsResponse data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mes filleuls', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (!data.canSponsor)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Parrainage suspendu — litiges repetes de vos filleuls',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!data.canSponsor)
          const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Actifs',
                  value: '${data.activeCount}/${data.maxSponsorships}',
                ),
                _StatItem(
                  label: 'Disponibles',
                  value: '${data.remainingSlots}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (data.sponsoredDrivers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Aucun filleul pour le moment.\n'
                  'Partagez votre numero pour parrainer un nouveau livreur.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...data.sponsoredDrivers.map(
            (driver) => _SponsoredDriverTile(driver: driver),
          ),
      ],
    );
  }
}

class _SponsoredDriverTile extends StatelessWidget {
  const _SponsoredDriverTile({required this.driver});

  final SponsoredDriver driver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (driver.status) {
      SponsorshipStatus.active => Colors.green,
      SponsorshipStatus.suspended => Colors.orange,
      SponsorshipStatus.terminated => Colors.grey,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            (driver.name ?? 'L').isNotEmpty
                ? (driver.name ?? 'L')[0].toUpperCase()
                : 'L',
          ),
        ),
        title: Text(driver.name ?? driver.phone),
        subtitle: Text(
          'Depuis le ${_formatDate(driver.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Chip(
          label: Text(
            driver.status.label,
            style: TextStyle(fontSize: 12, color: statusColor),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _SponsorSection extends StatelessWidget {
  const _SponsorSection({required this.sponsor});

  final SponsorInfo? sponsor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mon parrain', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (sponsor == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Aucun parrain enregistre',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(sponsor!.name ?? sponsor!.phone),
              subtitle: Text(sponsor!.phone),
              trailing: Chip(
                label: Text(
                  sponsor!.sponsorshipStatus.label,
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Reessayer')),
          ],
        ),
      ),
    );
  }
}

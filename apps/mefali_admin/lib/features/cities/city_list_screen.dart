import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import 'city_form_screen.dart';

/// Ecran liste des villes configurees.
class CityListScreen extends ConsumerWidget {
  const CityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(adminCitiesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminCitiesProvider),
        child: citiesAsync.when(
          data: (cities) => cities.isEmpty
              ? _buildEmptyState(context)
              : _buildCityList(context, ref, cities),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(adminCitiesProvider),
                  child: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCityForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une ville'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.location_city, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune ville configuree',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez une ville pour commencer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCityList(
    BuildContext context,
    WidgetRef ref,
    List<CityConfig> cities,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        final zoneCount = city.zonesGeojson?['features'] is List
            ? (city.zonesGeojson!['features'] as List).length
            : 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.location_city,
              color: city.isActive ? Colors.brown : Colors.grey,
            ),
            title: Text(city.cityName),
            subtitle: Text(
              'x${city.deliveryMultiplier.toStringAsFixed(2)} · '
              '${zoneCount > 0 ? '$zoneCount zone${zoneCount > 1 ? 's' : ''}' : 'Zones non definies'}',
            ),
            trailing: Switch(
              value: city.isActive,
              onChanged: (value) =>
                  _toggleActive(context, ref, city, value),
              activeThumbColor: Colors.green,
            ),
            onTap: () => _openCityForm(context, ref, city: city),
          ),
        );
      },
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    CityConfig city,
    bool newValue,
  ) async {
    if (!newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desactiver cette ville ?'),
          content: Text(
            'Les marchands de ${city.cityName} ne recevront plus de commandes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Desactiver'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final endpoint = ref.read(adminEndpointProvider);
      await endpoint.toggleCityActive(city.id, newValue);
      ref.invalidate(adminCitiesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? '${city.cityName} activee'
                  : '${city.cityName} desactivee',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openCityForm(
    BuildContext context,
    WidgetRef ref, {
    CityConfig? city,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CityFormScreen(city: city),
      ),
    );
  }
}

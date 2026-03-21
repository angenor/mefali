import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import 'driver_detail_screen.dart';

/// Ecran liste des livreurs pour l'admin.
class DriverListScreen extends ConsumerStatefulWidget {
  const DriverListScreen({super.key});

  @override
  ConsumerState<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends ConsumerState<DriverListScreen> {
  int _page = 1;
  String? _statusFilter;
  String? _cityFilter;
  bool? _availableFilter;
  String _search = '';
  final _searchController = TextEditingController();

  static const _statusOptions = [
    (null, 'Tous'),
    ('active', 'Actif'),
    ('pending_kyc', 'KYC en attente'),
    ('suspended', 'Suspendu'),
    ('deactivated', 'Desactive'),
  ];

  DriverListParams get _params => DriverListParams(
        page: _page,
        status: _statusFilter,
        cityId: _cityFilter,
        search: _search.isEmpty ? null : _search,
        available: _availableFilter,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(adminDriversProvider(_params));
    final cities = ref.watch(adminCitiesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un livreur...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (value) {
                  setState(() {
                    _search = value;
                    _page = 1;
                  });
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...List.generate(_statusOptions.length, (i) {
                      final (value, label) = _statusOptions[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilterChip(
                          label: Text(label),
                          selected: _statusFilter == value,
                          onSelected: (_) {
                            setState(() {
                              _statusFilter = value;
                              _page = 1;
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Disponible'),
                      selected: _availableFilter == true,
                      onSelected: (selected) {
                        setState(() {
                          _availableFilter = selected ? true : null;
                          _page = 1;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    cities.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (cityList) => DropdownButton<String?>(
                        value: _cityFilter,
                        hint: const Text('Ville'),
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Toutes les villes'),
                          ),
                          ...cityList.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.cityName),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _cityFilter = value;
                            _page = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: asyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (result) {
              if (result.items.isEmpty) {
                return const Center(child: Text('Aucun livreur'));
              }
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Ville')),
                          DataColumn(
                              label: Text('Livraisons'), numeric: true),
                          DataColumn(label: Text('Note'), numeric: true),
                          DataColumn(
                              label: Text('Litiges'), numeric: true),
                          DataColumn(label: Text('Disponible')),
                        ],
                        rows: result.items.map((d) {
                          return DataRow(
                            onSelectChanged: (_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DriverDetailScreen(driverId: d.id),
                                ),
                              );
                            },
                            cells: [
                              DataCell(Text(d.name ?? '-')),
                              DataCell(Text(d.status.name)),
                              DataCell(Text(d.cityName ?? '-')),
                              DataCell(Text('${d.deliveriesCount}')),
                              DataCell(
                                  Text(d.avgRating.toStringAsFixed(1))),
                              DataCell(Text('${d.disputesCount}')),
                              DataCell(Icon(
                                d.available
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: d.available
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  _buildPagination(result.total),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(int total) {
    final totalPages = (total / 20).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () => setState(() => _page--)
                : null,
          ),
          Text('Page $_page / $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () => setState(() => _page++)
                : null,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraichir',
            onPressed: () => ref.invalidate(adminDriversProvider(_params)),
          ),
        ],
      ),
    );
  }
}

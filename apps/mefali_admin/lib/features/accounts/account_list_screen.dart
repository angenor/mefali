import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import 'account_detail_screen.dart';

/// Ecran liste des comptes utilisateurs pour l'admin.
class AccountListScreen extends ConsumerStatefulWidget {
  const AccountListScreen({super.key});

  @override
  ConsumerState<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends ConsumerState<AccountListScreen> {
  String? _roleFilter;
  String? _statusFilter;
  String? _search;
  int _page = 1;
  Timer? _debounce;

  final _searchController = TextEditingController();

  static const _roleFilters = [
    (label: 'Tous', value: null),
    (label: 'Clients', value: 'client'),
    (label: 'Marchands', value: 'merchant'),
    (label: 'Livreurs', value: 'driver'),
    (label: 'Agents', value: 'agent'),
  ];

  static const _statusFilters = [
    (label: 'Tous', value: null),
    (label: 'Actifs', value: 'active'),
    (label: 'KYC', value: 'pending_kyc'),
    (label: 'Suspendus', value: 'suspended'),
    (label: 'Desactives', value: 'deactivated'),
  ];

  AdminUserListParams get _params => AdminUserListParams(
        page: _page,
        role: _roleFilter,
        status: _statusFilter,
        search: _search,
      );

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _search = value.isEmpty ? null : value;
        _page = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncData = ref.watch(adminUsersProvider(_params));

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou telephone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),

        // Filtres role
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roleFilters.map((f) {
                final isSelected = f.value == _roleFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _roleFilter = f.value;
                        _page = 1;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Filtres statut
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((f) {
                final isSelected = f.value == _statusFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _statusFilter = f.value;
                        _page = 1;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Liste
        Expanded(
          child: asyncData.when(
            loading: () => _buildSkeleton(context),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur de chargement',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(adminUsersProvider(_params)),
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            ),
            data: (result) {
              if (result.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun utilisateur trouve',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              const perPage = 20;
              final totalPages = (result.total / perPage).ceil();

              return Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 768) {
                          return _buildDataTable(result.items);
                        }
                        return RefreshIndicator(
                          onRefresh: () async =>
                              ref.invalidate(adminUsersProvider(_params)),
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: result.items.length,
                            itemBuilder: (context, index) {
                              final user = result.items[index];
                              return _UserCard(
                                user: user,
                                onTap: () => _openDetail(user.id),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _page > 1
                                ? () => setState(() => _page--)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('$_page / $totalPages'),
                          IconButton(
                            onPressed: _page < totalPages
                                ? () => setState(() => _page++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<AdminUserListItem> items) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Telephone')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Ville')),
            DataColumn(label: Text('Inscription')),
          ],
          rows: items.map((user) {
            return DataRow(
              onSelectChanged: (_) => _openDetail(user.id),
              cells: [
                DataCell(Text(user.name ?? '-')),
                DataCell(Text(user.phone)),
                DataCell(Text(_roleLabelStatic(user.role))),
                DataCell(_StatusBadge(status: user.status)),
                DataCell(Text(user.cityName ?? '-')),
                DataCell(Text(_formatDate(user.createdAt))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _roleLabelStatic(UserRole role) {
    return switch (role) {
      UserRole.client => 'Client',
      UserRole.merchant => 'Marchand',
      UserRole.driver => 'Livreur',
      UserRole.agent => 'Agent',
      UserRole.admin => 'Admin',
    };
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  Widget _buildSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 8,
      itemBuilder: (_, _) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: color),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 12, color: color),
                  ],
                ),
              ),
              Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(12))),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountDetailScreen(userId: userId),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final AdminUserListItem user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _roleColor(user.role),
                child: Text(
                  _roleInitial(user.role),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? user.phone,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.phone} · ${user.cityName ?? 'Ville non definie'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: user.status),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel(user.role),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  String _roleInitial(UserRole role) {
    return switch (role) {
      UserRole.client => 'C',
      UserRole.merchant => 'M',
      UserRole.driver => 'L',
      UserRole.agent => 'A',
      UserRole.admin => 'Ad',
    };
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.client => 'Client',
      UserRole.merchant => 'Marchand',
      UserRole.driver => 'Livreur',
      UserRole.agent => 'Agent',
      UserRole.admin => 'Admin',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      UserStatus.active => ('Actif', Colors.green),
      UserStatus.pendingKyc => ('KYC', Colors.orange),
      UserStatus.suspended => ('Suspendu', Colors.red),
      UserStatus.deactivated => ('Desactive', Colors.grey),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}

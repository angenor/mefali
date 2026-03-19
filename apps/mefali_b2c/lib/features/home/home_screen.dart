import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import '../order/orders_list_screen.dart';
import '../profile/profile_screen.dart';

/// Catégories de filtre affichées sur l'écran d'accueil (UX-DR spec AC5).
const _filterCategories = [
  (label: 'Tous', value: null),
  (label: 'Restaurants', value: 'restaurant'),
  (label: 'Maquis', value: 'maquis'),
  (label: 'Boulangeries', value: 'boulangerie'),
];

/// Ecran principal B2C avec navigation par onglets (AC6).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Client';

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeTab(userName: userName),
            const _PlaceholderTab(title: 'Recherche'),
            const _OrdersTab(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Recherche',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Onglet Accueil : grille de découverte restaurants avec filtres.
class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab({required this.userName});

  final String userName;

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  String? _selectedCategory; // null = "Tous"

  @override
  Widget build(BuildContext context) {
    // Toujours charger toutes les catégories — le filtrage se fait côté Flutter (AC5).
    final restaurantsAsync = ref.watch(restaurantDiscoveryProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Bienvenue ${widget.userName}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        _FilterChipsRow(
          selectedCategory: _selectedCategory,
          onCategorySelected: (value) {
            setState(() => _selectedCategory = value);
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: restaurantsAsync.when(
            loading: _buildSkeletonGrid,
            data: (restaurants) {
              final filtered = _selectedCategory == null
                  ? restaurants
                  : restaurants
                      .where((r) => r.category == _selectedCategory)
                      .toList();
              return filtered.isEmpty
                  ? _buildEmptyState(context)
                  : _buildGrid(filtered);
            },
            error: (error, _) => _buildErrorState(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 250,
      ),
      itemCount: 6,
      itemBuilder: (context, _) => const RestaurantCardSkeleton(),
    );
  }

  Widget _buildGrid(List<RestaurantSummary> restaurants) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 250,
      ),
      itemCount: restaurants.length,
      itemBuilder: (_, index) {
        final restaurant = restaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          onTap: () => context.push(
            '/restaurant/${restaurant.id}',
            extra: restaurant,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun restaurant disponible',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez plus tard ou changez de filtre.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les restaurants',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(restaurantDiscoveryProvider(null)),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final cat in _filterCategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat.label),
                selected: selectedCategory == cat.value,
                onSelected: (_) => onCategorySelected(cat.value),
              ),
            ),
        ],
      ),
    );
  }
}

/// Onglet Commandes : reutilise le contenu de OrdersListScreen.
class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerOrdersProvider);
        await ref.read(customerOrdersProvider.future);
      },
      child: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Impossible de charger les commandes',
                  style: textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(customerOrdersProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Aucune commande', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Vos commandes apparaitront ici',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final active = orders
              .where((o) =>
                  o.status != OrderStatus.delivered &&
                  o.status != OrderStatus.cancelled)
              .toList();
          final past = orders
              .where((o) =>
                  o.status == OrderStatus.delivered ||
                  o.status == OrderStatus.cancelled)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                Text('En cours',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final order in active)
                  OrderListItem(
                    order: order,
                    onTap: () =>
                        context.push('/order/tracking/${order.id}'),
                  ),
                const SizedBox(height: 24),
              ],
              if (past.isNotEmpty) ...[
                Text('Historique',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final order in past) OrderListItem(order: order),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

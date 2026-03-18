import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Filtre actif pour la liste des produits.
enum _StockFilter { all, lowStock, unavailable }

/// Liste des produits du catalogue marchand avec gestion stock.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  _StockFilter _filter = _StockFilter.all;

  List<Product> _applyFilter(List<Product> products) {
    switch (_filter) {
      case _StockFilter.all:
        return products;
      case _StockFilter.lowStock:
        return products.where((p) {
          if (p.initialStock <= 0) return false;
          return p.stock > 0 && p.stock <= (p.initialStock * 0.2).ceil();
        }).toList();
      case _StockFilter.unavailable:
        return products.where((p) => p.stock == 0).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(merchantProductsProvider);
    final alertsAsync = ref.watch(stockAlertsProvider);

    return Scaffold(
      body: productsAsync.when(
        loading: () => _buildSkeletonGrid(context),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(merchantProductsProvider),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun produit',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre premier produit au catalogue.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/catalogue/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un produit'),
                  ),
                ],
              ),
            );
          }

          final filtered = _applyFilter(products);

          return CustomScrollView(
            slivers: [
              // Alertes stock (T10)
              alertsAsync.whenOrNull(
                    data: (alerts) {
                      if (alerts.isEmpty) return const SliverToBoxAdapter();
                      return SliverToBoxAdapter(
                        child: _StockAlertsSection(
                          alerts: alerts,
                          products: products,
                          onAcknowledge: (alertId) async {
                            await ref
                                .read(productCatalogueProvider.notifier)
                                .acknowledgeAlert(alertId);
                          },
                        ),
                      );
                    },
                  ) ??
                  const SliverToBoxAdapter(),

              // Filtres chips (T8.2)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _filter == _StockFilter.all,
                        onSelected: (_) =>
                            setState(() => _filter = _StockFilter.all),
                      ),
                      FilterChip(
                        label: const Text('Stock bas'),
                        selected: _filter == _StockFilter.lowStock,
                        onSelected: (_) =>
                            setState(() => _filter = _StockFilter.lowStock),
                      ),
                      FilterChip(
                        label: const Text('Indisponible'),
                        selected: _filter == _StockFilter.unavailable,
                        onSelected: (_) =>
                            setState(() => _filter = _StockFilter.unavailable),
                      ),
                    ],
                  ),
                ),
              ),

              // Grille produits
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = filtered[index];
                      return _ProductCard(
                        product: product,
                        onTap: () =>
                            context.push('/catalogue/edit', extra: product),
                        onStockTap: () => _showStockBottomSheet(product),
                      );
                    },
                    childCount: filtered.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: productsAsync.maybeWhen(
        data: (products) => products.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => context.push('/catalogue/add'),
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  // T9 — Bottom sheet ajustement stock
  void _showStockBottomSheet(Product product) {
    final controller = TextEditingController(text: product.stock.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Stock : ${product.name}',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nouveau stock',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Champ requis';
                  }
                  final n = int.tryParse(value);
                  if (n == null) return 'Nombre invalide';
                  if (n < 0) return 'Le stock doit etre >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (ctx, ref, _) {
                  final state = ref.watch(productCatalogueProvider);
                  final isLoading = state is AsyncLoading;

                  return FilledButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final stock = int.parse(controller.text);
                            await ref
                                .read(productCatalogueProvider.notifier)
                                .updateStock(
                                  productId: product.id,
                                  stock: stock,
                                );

                            final result =
                                ref.read(productCatalogueProvider);
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            if (!mounted) return;

                            if (result is AsyncData) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stock mis a jour'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else if (result
                                is AsyncError<void>) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Erreur: ${result.error}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(days: 1),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    textColor: Colors.white,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Mettre a jour'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Stock badge helper ---

enum _StockLevel { ok, low, unavailable }

_StockLevel _getStockLevel(Product product) {
  if (product.stock == 0) return _StockLevel.unavailable;
  if (product.initialStock > 0 &&
      product.stock <= (product.initialStock * 0.2).ceil()) {
    return _StockLevel.low;
  }
  return _StockLevel.ok;
}

// --- Product card with stock badge (T8) ---

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onStockTap,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onStockTap;

  @override
  Widget build(BuildContext context) {
    final level = _getStockLevel(product);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.photoUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, _) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Center(
                            child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.broken_image, size: 48),
                      ),
                    )
                  : Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.fastfood, size: 48),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price} FCFA',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 4),
                  // Stock badge (T8.1)
                  GestureDetector(
                    onTap: onStockTap,
                    child: _StockBadge(
                        level: level, stock: product.stock),
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

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.level, required this.stock});

  final _StockLevel level;
  final int stock;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String label;

    switch (level) {
      case _StockLevel.ok:
        bgColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        icon = Icons.check_circle_outline;
        label = '$stock';
      case _StockLevel.low:
        bgColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        icon = Icons.warning_amber;
        label = 'Stock bas';
      case _StockLevel.unavailable:
        bgColor = const Color(0xFFF44336);
        textColor = Colors.white;
        icon = Icons.error_outline;
        label = 'Indisponible';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Stock alerts section (T10) ---

class _StockAlertsSection extends StatelessWidget {
  const _StockAlertsSection({
    required this.alerts,
    required this.products,
    required this.onAcknowledge,
  });

  final List<StockAlert> alerts;
  final List<Product> products;
  final Future<void> Function(String alertId) onAcknowledge;

  String _productName(String productId) {
    final p = products.where((p) => p.id == productId).firstOrNull;
    return p?.name ?? 'Produit inconnu';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notification_important,
                  color: Color(0xFFFF9800), size: 20),
              const SizedBox(width: 8),
              Text(
                'Alertes stock (${alerts.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFFF9800),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...alerts.map((alert) => Card(
                color: const Color(0xFFFFF3E0),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.warning_amber,
                      color: Color(0xFFFF9800)),
                  title: Text(_productName(alert.productId)),
                  subtitle: Text(
                      'Stock: ${alert.currentStock}/${alert.initialStock}'),
                  trailing: TextButton(
                    onPressed: () => onAcknowledge(alert.id),
                    child: const Text('Vu'),
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Widget _buildSkeletonGrid(BuildContext context) {
  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
    ),
    itemCount: 6,
    itemBuilder: (context, index) {
      final color = Theme.of(context).colorScheme.surfaceContainerHighest;
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Container(color: color)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

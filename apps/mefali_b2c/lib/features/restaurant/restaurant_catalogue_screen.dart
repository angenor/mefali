import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';
import 'package:url_launcher/url_launcher.dart';

import '../order/saved_addresses_provider.dart';

class _IsOrderingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setOrdering(bool value) => state = value;
}

final _isOrderingProvider =
    NotifierProvider.autoDispose<_IsOrderingNotifier, bool>(
  _IsOrderingNotifier.new,
);

/// Ecran catalogue restaurant B2C (story 4.2).
/// Affiche les produits dans un MefaliBottomSheet progressif.
class RestaurantCatalogueScreen extends ConsumerWidget {
  const RestaurantCatalogueScreen({
    required this.restaurantId,
    required this.restaurant,
    super.key,
  });

  final String restaurantId;
  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          _RestaurantBackground(restaurant: restaurant),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black38,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Bottom sheet
          MefaliBottomSheet(
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  _RestaurantHeader(restaurant: restaurant),
                  const Divider(height: 1),
                  _ProductsList(restaurantId: restaurantId),
                ],
              );
            },
          ),
          // Cart bar sticky with slide-up animation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer(
              builder: (context, ref, child) {
                final cart = ref.watch(cartProvider);
                final hasItems = cart.isNotEmpty;
                final notifier = ref.read(cartProvider.notifier);
                return AnimatedSlide(
                  offset: hasItems ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: hasItems
                      ? CartBar(
                          itemCount: notifier.totalItems,
                          totalPrice: notifier.totalPrice,
                          onTap: () => _showPriceBreakdown(
                            context,
                            ref,
                            restaurant,
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceBreakdown(
    BuildContext screenContext,
    WidgetRef ref,
    RestaurantSummary restaurant,
  ) {
    showModalBottomSheet<void>(
      context: screenContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (_, sheetRef, _) {
            final cart = sheetRef.watch(cartProvider);
            final isOrdering = sheetRef.watch(_isOrderingProvider);
            if (cart.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              });
              return const SizedBox.shrink();
            }
            final items = cart.values.toList();
            final notifier = sheetRef.read(cartProvider.notifier);
            return PriceBreakdownSheet(
              items: items,
              deliveryFee: restaurant.deliveryFee,
              onIncrement: notifier.incrementProduct,
              onDecrement: notifier.decrementProduct,
              isOrdering: isOrdering,
              onOrder: (paymentType) => _selectAddressAndOrder(
                screenContext,
                sheetContext,
                sheetRef,
                restaurant,
                items,
                paymentType,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectAddressAndOrder(
    BuildContext screenContext,
    BuildContext sheetContext,
    WidgetRef ref,
    RestaurantSummary restaurant,
    List<CartItem> items,
    String paymentType,
  ) async {
    if (!sheetContext.mounted) return;
    // Fermer le bottom sheet avant de naviguer
    Navigator.of(sheetContext).pop();
    if (!screenContext.mounted) return;
    final addressResult = await GoRouter.of(screenContext)
        .push<AddressResult>('/order/address-selection');
    if (addressResult == null || !screenContext.mounted) return;

    // Sauvegarder l'adresse pour reutilisation future
    final db = ref.read(mefaliDatabaseProvider);
    await saveAddress(
      db,
      id: '${addressResult.lat}_${addressResult.lng}',
      address: addressResult.address,
      lat: addressResult.lat,
      lng: addressResult.lng,
    );
    ref.invalidate(savedAddressesProvider);

    if (!screenContext.mounted) return;
    await _placeOrder(
      screenContext,
      ref,
      restaurant,
      items,
      paymentType,
      addressResult,
    );
  }

  Future<void> _placeOrder(
    BuildContext context,
    WidgetRef ref,
    RestaurantSummary restaurant,
    List<CartItem> items,
    String paymentType,
    AddressResult address,
  ) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    ref.read(_isOrderingProvider.notifier).setOrdering(true);
    try {
      final orderEndpoint = OrderEndpoint(
        ref.read(dioProvider),
      );
      final result = await orderEndpoint.createOrder(
        merchantId: restaurant.id,
        items: items
            .map((item) => {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                })
            .toList(),
        paymentType: paymentType,
        deliveryAddress: address.address,
        deliveryLat: address.lat,
        deliveryLng: address.lng,
      );

      ref.read(_isOrderingProvider.notifier).setOrdering(false);

      // Mobile Money: open CinetPay payment URL and navigate to payment status
      if (paymentType == 'mobile_money' && result.paymentUrl != null) {
        // H1: validate URL scheme before launching
        final uri = Uri.parse(result.paymentUrl!);
        if (uri.scheme != 'https') {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Erreur: URL de paiement invalide'),
              backgroundColor: colorScheme.error,
            ),
          );
          return;
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // C3: cart is cleared in PaymentStatusScreen on success, not here
        if (!context.mounted) return;
        router.go('/order/payment-status/${result.order.id}');
        return;
      }

      // COD: clear cart and navigate to tracking
      ref.read(cartProvider.notifier).clear();
      router.go('/order/tracking/${result.order.id}');
    } on Exception catch (e) {
      ref.read(_isOrderingProvider.notifier).setOrdering(false);
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      // Check if it's a payment service error (CinetPay unavailable)
      final isCinetPayError = errorMsg.contains('service') ||
          errorMsg.contains('payment') ||
          errorMsg.contains('502');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isCinetPayError
                ? 'Service de paiement temporairement indisponible. Vous pouvez payer en cash a la livraison ou reessayer.'
                : 'Erreur: $errorMsg',
          ),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Reessayer',
            textColor: colorScheme.onError,
            onPressed: () =>
                _placeOrder(context, ref, restaurant, items, paymentType, address),
          ),
        ),
      );
    }
  }
}

class _RestaurantBackground extends StatelessWidget {
  const _RestaurantBackground({required this.restaurant});

  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      width: double.infinity,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.restaurant, size: 64, color: Colors.white54),
      ),
    );
    if (restaurant.photoUrl == null) return fallback;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: restaurant.photoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  const _RestaurantHeader({required this.restaurant});

  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              VendorStatusIndicator(status: restaurant.status),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (restaurant.avgRating > 0) ...[
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  restaurant.avgRating.toStringAsFixed(1),
                  style: textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                Text('•', style: textTheme.bodySmall),
                const SizedBox(width: 8),
              ],
              Text(
                '${formatFcfa(restaurant.deliveryFee)} livraison',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductsList extends ConsumerWidget {
  const _ProductsList({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(restaurantProductsProvider(restaurantId));

    return productsAsync.when(
      loading: () => Column(
        children: List.generate(
          5,
          (_) => const ProductListTileSkeleton(),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const _EmptyState();
        }
        return Column(
          children: [
            for (final product in products)
              ProductListTile(
                product: product,
                onAdd: product.isOutOfStock
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} ajoute au panier'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
              ),
            // Bottom padding for cart bar
            const SizedBox(height: 80),
          ],
        );
      },
      error: (error, _) => _ErrorState(
        onRetry: () =>
            ref.invalidate(restaurantProductsProvider(restaurantId)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Ce restaurant n\'a pas encore de produits',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez bientot !',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger les produits',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}

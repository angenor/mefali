import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import '../catalogue/product_list_screen.dart';
import '../orders/orders_screen.dart';
import '../sales/sales_dashboard_screen.dart';

/// Ecran principal B2B avec TabBar (Commandes | Catalogue | Stats).
class B2bHomeScreen extends ConsumerStatefulWidget {
  const B2bHomeScreen({super.key});

  @override
  ConsumerState<B2bHomeScreen> createState() => _B2bHomeScreenState();
}

class _B2bHomeScreenState extends ConsumerState<B2bHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onStatusChanged(VendorStatus newStatus) {
    ref.read(vendorStatusProvider.notifier).changeStatus(newStatus).then((_) {
      final state = ref.read(vendorStatusProvider);
      if (mounted) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(days: 1),
              showCloseIcon: true,
              closeIconColor: Colors.white,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Statut mis à jour'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(currentMerchantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('mefali Marchand'),
        actions: [
          merchantAsync.when(
            data: (merchant) => VendorStatusIndicator(
              status: merchant.displayStatus,
              interactive: true,
              onStatusChanged: _onStatusChanged,
            ),
            loading: () => const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Horaires',
            onPressed: () => context.push('/settings/hours'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logoutAndRevoke(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _OrdersTabWithBadge(ref: ref),
            const Tab(text: 'Catalogue'),
            const Tab(text: 'Stats'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bandeau auto-pause
          merchantAsync.whenOrNull(
                data: (merchant) {
                  if (merchant.displayStatus != VendorStatus.autoPaused) return null;
                  return _AutoPauseBanner(
                    onReactivate: () => _onStatusChanged(VendorStatus.open),
                  );
                },
              ) ??
              const SizedBox.shrink(),
          // Contenu principal
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                // Commandes — actif
                OrdersScreen(),
                // Catalogue — actif
                ProductListScreen(),
                // Stats — dashboard ventes
                SalesDashboardScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet Commandes avec badge compteur des commandes pending.
class _OrdersTabWithBadge extends StatelessWidget {
  const _OrdersTabWithBadge({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(merchantOrdersProvider);
    final pendingCount = ordersAsync.whenOrNull(
          data: (orders) =>
              orders.where((o) => o.status == OrderStatus.pending).length,
        ) ??
        0;

    return Tab(
      child: pendingCount > 0
          ? Badge(
              label: Text('$pendingCount'),
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Commandes'),
              ),
            )
          : const Text('Commandes'),
    );
  }
}

/// Bandeau orange affiche quand le marchand est en auto-pause.
class _AutoPauseBanner extends StatelessWidget {
  const _AutoPauseBanner({required this.onReactivate});

  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: MefaliColors.warningLight.withValues(alpha: 0.15),
      leading: const Icon(Icons.pause_circle, color: MefaliColors.warningLight),
      content: const Text(
        'Vous êtes en pause automatique — 3 commandes sans réponse',
      ),
      actions: [
        TextButton(
          onPressed: onReactivate,
          child: const Text('Réactiver'),
        ),
      ],
    );
  }
}

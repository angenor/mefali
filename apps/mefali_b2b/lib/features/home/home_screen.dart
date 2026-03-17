import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import '../catalogue/product_list_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mefali Marchand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logoutAndRevoke(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Commandes'),
            Tab(text: 'Catalogue'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Commandes — placeholder
          const Center(child: Text('Commandes (bientot)')),
          // Catalogue — active
          const ProductListScreen(),
          // Stats — placeholder
          const Center(child: Text('Statistiques (bientot)')),
        ],
      ),
    );
  }
}

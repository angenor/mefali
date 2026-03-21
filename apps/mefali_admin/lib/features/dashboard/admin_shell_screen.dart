import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import 'admin_dashboard_screen.dart';
import '../accounts/account_list_screen.dart';
import '../cities/city_list_screen.dart';
import '../disputes/dispute_list_screen.dart';
import '../merchants/merchant_list_screen.dart';
import '../drivers/driver_list_screen.dart';

/// Shell admin avec NavigationRail lateral et contenu dashboard.
class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('mefali Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long),
                  label: Text('Commandes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.store),
                  label: Text('Marchands'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.moped),
                  label: Text('Livreurs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.warning_amber),
                  label: Text('Litiges'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.location_city),
                  label: Text('Villes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Comptes'),
                ),
              ],
            ),
          if (isWide) const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long),
                  label: 'Commandes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.store),
                  label: 'Marchands',
                ),
                NavigationDestination(
                  icon: Icon(Icons.moped),
                  label: 'Livreurs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.warning_amber),
                  label: 'Litiges',
                ),
                NavigationDestination(
                  icon: Icon(Icons.location_city),
                  label: 'Villes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people),
                  label: 'Comptes',
                ),
              ],
            ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboardScreen();
      case 2:
        return const MerchantListScreen();
      case 3:
        return const DriverListScreen();
      case 4:
        return const DisputeListScreen();
      case 5:
        return const CityListScreen();
      case 6:
        return const AccountListScreen();
      default:
        return Center(
          child: Text(
            'Bientot disponible',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
    }
  }
}

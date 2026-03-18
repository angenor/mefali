import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_b2b/app.dart';
import 'package:mefali_b2b/features/auth/phone_screen.dart';
import 'package:mefali_b2b/features/catalogue/product_form_screen.dart';
import 'package:mefali_b2b/features/catalogue/product_list_screen.dart';
import 'package:mefali_b2b/features/home/home_screen.dart';
import 'package:mefali_b2b/features/sales/sales_dashboard_screen.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

void main() {
  testWidgets('MefaliB2bApp renders login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2bApp()));
    await tester.pumpAndSettle();

    // Should show the login screen by default
    expect(find.text('Connexion Marchand'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('B2bPhoneScreen has phone field and submit button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const B2bPhoneScreen()),
      ),
    );

    expect(find.text('Numero de telephone'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('B2bPhoneScreen validates empty phone', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const B2bPhoneScreen()),
      ),
    );

    // Tap submit without entering phone
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Veuillez entrer votre numero'), findsOneWidget);
  });

  testWidgets('ProductListScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(<Product>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aucun produit'), findsOneWidget);
    expect(find.text('Ajouter un produit'), findsOneWidget);
  });

  testWidgets('ProductListScreen shows product grid', (tester) async {
    final products = [
      Product(
        id: '00000000-0000-0000-0000-000000000001',
        merchantId: '00000000-0000-0000-0000-000000000002',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 50,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '00000000-0000-0000-0000-000000000003',
        merchantId: '00000000-0000-0000-0000-000000000002',
        name: 'Alloco',
        price: 300,
        stock: 30,
        initialStock: 30,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Garba'), findsOneWidget);
    expect(find.text('500 FCFA'), findsOneWidget);
    expect(find.text('Alloco'), findsOneWidget);
    expect(find.text('300 FCFA'), findsOneWidget);
  });

  testWidgets('ProductFormScreen create mode has correct fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const ProductFormScreen()),
      ),
    );

    expect(find.text('Ajouter un produit'), findsOneWidget);
    expect(find.text('Nom du produit'), findsOneWidget);
    expect(find.text('Prix (FCFA)'), findsOneWidget);
    expect(find.text('Description (optionnel)'), findsOneWidget);
    expect(find.text('Stock (optionnel)'), findsOneWidget);
    expect(find.text('Ajouter'), findsOneWidget);
  });

  testWidgets('ProductFormScreen edit mode shows product data', (tester) async {
    final product = Product(
      id: '00000000-0000-0000-0000-000000000001',
      merchantId: '00000000-0000-0000-0000-000000000002',
      name: 'Garba',
      price: 500,
      stock: 50,
      initialStock: 50,
      description: 'Attieke + thon',
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: ProductFormScreen(product: product)),
      ),
    );

    expect(find.text('Modifier le produit'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    // Delete icon in app bar
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('ProductFormScreen validates empty name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const ProductFormScreen()),
      ),
    );

    // Find and tap the FilledButton (submit)
    final submitButton = find.widgetWithText(FilledButton, 'Ajouter');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Le nom est requis'), findsOneWidget);
    expect(find.text('Le prix est requis'), findsOneWidget);
  });

  // --- Stock management tests (story 3.4) ---

  testWidgets('ProductListScreen shows green badge for OK stock', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Stock > 20% shows the stock count as badge text
    expect(find.text('50'), findsOneWidget);
    expect(find.text('Garba'), findsOneWidget);
  });

  testWidgets('ProductListScreen shows orange badge for low stock', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Alloco',
        price: 300,
        stock: 10,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // "Stock bas" appears in badge AND filter chip
    expect(find.text('Stock bas'), findsWidgets);
  });

  testWidgets('ProductListScreen shows red badge for zero stock', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Thiep',
        price: 1500,
        stock: 0,
        initialStock: 50,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // "Indisponible" appears in badge AND filter chip
    expect(find.text('Indisponible'), findsWidgets);
  });

  testWidgets('ProductListScreen shows filter chips', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('Stock bas'), findsWidgets);
    expect(find.text('Indisponible'), findsWidgets);
  });

  testWidgets('ProductListScreen shows stock alerts section', (tester) async {
    final products = [
      Product(
        id: 'prod-1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 5,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final alerts = [
      StockAlert(
        id: 'alert-1',
        merchantId: '2',
        productId: 'prod-1',
        alertType: 'below_20_percent',
        currentStock: 5,
        initialStock: 100,
        triggeredAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(alerts),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alertes stock (1)'), findsOneWidget);
    expect(find.text('Vu'), findsOneWidget);
    expect(find.text('Stock: 5/100'), findsOneWidget);
  });

  testWidgets('Tapping "Indisponible" filter shows only zero-stock products', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2',
        merchantId: '2',
        name: 'Alloco',
        price: 300,
        stock: 0,
        initialStock: 50,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Both products visible initially
    expect(find.text('Garba'), findsOneWidget);
    expect(find.text('Alloco'), findsOneWidget);

    // Tap "Indisponible" filter chip
    await tester.tap(find.widgetWithText(FilterChip, 'Indisponible'));
    await tester.pumpAndSettle();

    // Only zero-stock product visible
    expect(find.text('Alloco'), findsOneWidget);
    expect(find.text('Garba'), findsNothing);
  });

  testWidgets('Tapping "Stock bas" filter shows only low-stock products', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2',
        merchantId: '2',
        name: 'Alloco',
        price: 300,
        stock: 10,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Both products visible initially
    expect(find.text('Garba'), findsOneWidget);
    expect(find.text('Alloco'), findsOneWidget);

    // Tap "Stock bas" filter chip
    await tester.tap(find.widgetWithText(FilterChip, 'Stock bas'));
    await tester.pumpAndSettle();

    // Only low-stock product visible (10/100 = 10% <= 20%)
    expect(find.text('Alloco'), findsOneWidget);
    expect(find.text('Garba'), findsNothing);
  });

  testWidgets('Tapping "Tous" filter after filtering restores all products', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2',
        merchantId: '2',
        name: 'Alloco',
        price: 300,
        stock: 0,
        initialStock: 50,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Filter to "Indisponible"
    await tester.tap(find.widgetWithText(FilterChip, 'Indisponible'));
    await tester.pumpAndSettle();
    expect(find.text('Garba'), findsNothing);

    // Tap "Tous" to restore
    await tester.tap(find.widgetWithText(FilterChip, 'Tous'));
    await tester.pumpAndSettle();
    expect(find.text('Garba'), findsOneWidget);
    expect(find.text('Alloco'), findsOneWidget);
  });

  testWidgets('Alert section hidden when no alerts', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // No alerts section visible
    expect(find.text('Alertes stock'), findsNothing);
    expect(find.byIcon(Icons.notification_important), findsNothing);
  });

  // --- Sales Dashboard tests (story 3.7) ---

  WeeklySalesState makeStatsState({
    int currentTotal = 4700000,
    int currentCount = 47,
    int prevTotal = 4000000,
    int prevCount = 40,
    bool isCached = false,
  }) {
    return WeeklySalesState(
      stats: WeeklySales(
        period: const WeekPeriod(start: '2026-03-09', end: '2026-03-15'),
        currentWeek: WeekSummary(
          totalSales: currentTotal,
          orderCount: currentCount,
          averageOrder: currentCount > 0 ? currentTotal ~/ currentCount : 0,
        ),
        previousWeek: WeekSummary(
          totalSales: prevTotal,
          orderCount: prevCount,
          averageOrder: prevCount > 0 ? prevTotal ~/ prevCount : 0,
        ),
        productBreakdown: currentTotal > 0
            ? [
                ProductSales(
                  productId: '1',
                  productName: 'Garba',
                  quantitySold: 23,
                  revenue: 2300000,
                  percentage: 48.9,
                ),
                ProductSales(
                  productId: '2',
                  productName: 'Alloco-poisson',
                  quantitySold: 15,
                  revenue: 1500000,
                  percentage: 31.9,
                ),
              ]
            : [],
      ),
      lastSync: DateTime.now(),
      isCached: isCached,
    );
  }

  testWidgets('SalesDashboardScreen shows data with products', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyStatsProvider.overrideWith(
            (ref) => Future.value(makeStatsState()),
          ),
        ],
        child: const MaterialApp(home: SalesDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total ventes'), findsOneWidget);
    expect(find.text('Commandes'), findsOneWidget);
    expect(find.text('47'), findsOneWidget);
    expect(find.text('Garba'), findsOneWidget);
    expect(find.text('Alloco-poisson'), findsOneWidget);
    expect(find.text('Repartition par produit'), findsOneWidget);
    expect(find.text('Comparaison'), findsOneWidget);
  });

  testWidgets('SalesDashboardScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyStatsProvider.overrideWith(
            (ref) => Future.value(makeStatsState(
              currentTotal: 0,
              currentCount: 0,
              prevTotal: 0,
              prevCount: 0,
            )),
          ),
        ],
        child: const MaterialApp(home: SalesDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pas de commandes cette semaine'), findsOneWidget);
    expect(find.text('Continuez a ameliorer votre catalogue !'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long), findsOneWidget);
  });

  testWidgets('SalesDashboardScreen shows skeleton loading', (tester) async {
    final completer = Completer<WeeklySalesState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyStatsProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: const MaterialApp(home: SalesDashboardScreen()),
      ),
    );
    await tester.pump();

    // Skeleton should be visible, not the dashboard content
    expect(find.text('Total ventes'), findsNothing);
    expect(find.text('Pas de commandes cette semaine'), findsNothing);

    // Complete to avoid dangling future
    completer.complete(makeStatsState());
  });

  testWidgets('SalesDashboardScreen shows green growth for positive', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyStatsProvider.overrideWith(
            (ref) => Future.value(makeStatsState(
              currentTotal: 5000000,
              prevTotal: 4000000,
            )),
          ),
        ],
        child: const MaterialApp(home: SalesDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Growth arrow up icon should be visible
    expect(find.byIcon(Icons.arrow_upward), findsWidgets);
  });

  testWidgets('SalesDashboardScreen shows red growth for negative', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyStatsProvider.overrideWith(
            (ref) => Future.value(makeStatsState(
              currentTotal: 3000000,
              prevTotal: 4000000,
            )),
          ),
        ],
        child: const MaterialApp(home: SalesDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Growth arrow down icon should be visible
    expect(find.byIcon(Icons.arrow_downward), findsWidgets);
  });

  testWidgets('SalesDashboardScreen shows cache banner when offline', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyStatsProvider.overrideWith(
            (ref) => Future.value(makeStatsState(isCached: true)),
          ),
        ],
        child: const MaterialApp(home: SalesDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.textContaining('Donnees en cache'), findsOneWidget);
  });

  // --- VendorStatus / B2B Home tests (story 3.5) ---

  Merchant makeMerchant(VendorStatus status) {
    return Merchant(
      id: '00000000-0000-0000-0000-000000000001',
      userId: '00000000-0000-0000-0000-000000000002',
      name: 'Chez Adjoua',
      status: status,
      consecutiveNoResponse: status == VendorStatus.autoPaused ? 3 : 0,
      onboardingStep: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  testWidgets('B2bHomeScreen shows VendorStatusIndicator with open status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentMerchantProvider.overrideWith(
            (ref) => Future.value(makeMerchant(VendorStatus.open)),
          ),
        ],
        child: const MaterialApp(home: B2bHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ouvert'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('B2bHomeScreen shows auto-pause banner when auto_paused', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentMerchantProvider.overrideWith(
            (ref) => Future.value(makeMerchant(VendorStatus.autoPaused)),
          ),
        ],
        child: const MaterialApp(home: B2bHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auto-pause'), findsOneWidget);
    expect(
      find.text('Vous etes en pause automatique — 3 commandes sans reponse'),
      findsOneWidget,
    );
    expect(find.text('Reactiver'), findsOneWidget);
  });

  testWidgets('B2bHomeScreen hides auto-pause banner when open', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentMerchantProvider.overrideWith(
            (ref) => Future.value(makeMerchant(VendorStatus.open)),
          ),
        ],
        child: const MaterialApp(home: B2bHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Vous etes en pause automatique — 3 commandes sans reponse'),
      findsNothing,
    );
  });

  testWidgets('Stock badge renders check icon for OK stock', (tester) async {
    final products = [
      Product(
        id: '1',
        merchantId: '2',
        name: 'Garba',
        price: 500,
        stock: 50,
        initialStock: 100,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantProductsProvider.overrideWith(
            (ref) => Future.value(products),
          ),
          stockAlertsProvider.overrideWith(
            (ref) => Future.value(<StockAlert>[]),
          ),
        ],
        child: const MaterialApp(home: ProductListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // OK stock shows check icon
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    // Low stock warning icon absent (all stock OK)
    expect(find.byIcon(Icons.warning_amber), findsNothing);
    // Error icon absent
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}

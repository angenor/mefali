import '../enums/order_status.dart';
import '../enums/vendor_status.dart';
import 'merchant.dart';
import 'order.dart';
import 'order_item.dart';
import 'product.dart';
import 'weekly_sales.dart';

/// Donnees fictives pour le mode demo B2B.
///
/// Toutes les donnees sont locales et statiques — aucun appel API.
/// Les prix sont en centimes (500 FCFA = 50000 centimes).
class DemoData {
  DemoData._();

  static const _merchantId = '00000000-0000-0000-0000-000000000001';
  static const _userId = '00000000-0000-0000-0000-000000000002';
  static const _customerId = '00000000-0000-0000-0000-000000000003';
  static const _orderId = '00000000-0000-0000-0000-000000000010';

  static final _now = DateTime(2026, 3, 19, 12, 0);

  /// Restaurant fictif "Chez Dramane" a Bouake.
  static final merchant = Merchant(
    id: _merchantId,
    userId: _userId,
    name: 'Chez Dramane',
    address: 'Marche central, Bouake',
    status: VendorStatus.open,
    consecutiveNoResponse: 0,
    category: 'restaurant',
    onboardingStep: 5,
    createdAt: _now,
    updatedAt: _now,
  );

  /// Catalogue de 4 produits typiques de Bouake.
  static final products = [
    Product(
      id: '00000000-0000-0000-0000-000000000101',
      merchantId: _merchantId,
      name: 'Garba',
      price: 50000,
      stock: 50,
      initialStock: 50,
      isAvailable: true,
      createdAt: _now,
      updatedAt: _now,
    ),
    Product(
      id: '00000000-0000-0000-0000-000000000102',
      merchantId: _merchantId,
      name: 'Alloco-Poisson',
      price: 80000,
      stock: 30,
      initialStock: 30,
      isAvailable: true,
      createdAt: _now,
      updatedAt: _now,
    ),
    Product(
      id: '00000000-0000-0000-0000-000000000103',
      merchantId: _merchantId,
      name: 'Attieke-Poisson',
      price: 70000,
      stock: 25,
      initialStock: 25,
      isAvailable: true,
      createdAt: _now,
      updatedAt: _now,
    ),
    Product(
      id: '00000000-0000-0000-0000-000000000104',
      merchantId: _merchantId,
      name: 'Jus Bissap',
      price: 20000,
      stock: 40,
      initialStock: 40,
      isAvailable: true,
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  /// Commande simulee : 2x Garba + 1x Jus Bissap = 1200 FCFA.
  static Order createDemoOrder() => Order(
        id: _orderId,
        customerId: _customerId,
        merchantId: _merchantId,
        status: OrderStatus.pending,
        paymentType: 'cod',
        paymentStatus: 'pending',
        subtotal: 120000,
        deliveryFee: 0,
        total: 120000,
        notes: 'Sans piment svp',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          OrderItem(
            id: '00000000-0000-0000-0000-000000000201',
            orderId: _orderId,
            productId: '00000000-0000-0000-0000-000000000101',
            quantity: 2,
            unitPrice: 50000,
            createdAt: DateTime.now(),
            productName: 'Garba',
          ),
          OrderItem(
            id: '00000000-0000-0000-0000-000000000202',
            orderId: _orderId,
            productId: '00000000-0000-0000-0000-000000000104',
            quantity: 1,
            unitPrice: 20000,
            createdAt: DateTime.now(),
            productName: 'Jus Bissap',
          ),
        ],
      );

  /// Stats hebdomadaires fictives : 47 commandes, 58 500 FCFA, +12%.
  static const weeklySales = WeeklySales(
    period: WeekPeriod(start: '2026-03-16', end: '2026-03-22'),
    currentWeek: WeekSummary(
      totalSales: 5850000,
      orderCount: 47,
      averageOrder: 124468,
    ),
    previousWeek: WeekSummary(
      totalSales: 5220000,
      orderCount: 42,
      averageOrder: 124286,
    ),
    productBreakdown: [
      ProductSales(
        productId: '00000000-0000-0000-0000-000000000101',
        productName: 'Garba',
        quantitySold: 23,
        revenue: 2300000,
        percentage: 49.0,
      ),
      ProductSales(
        productId: '00000000-0000-0000-0000-000000000102',
        productName: 'Alloco-Poisson',
        quantitySold: 15,
        revenue: 1500000,
        percentage: 32.0,
      ),
      ProductSales(
        productId: '00000000-0000-0000-0000-000000000103',
        productName: 'Attieke-Poisson',
        quantitySold: 9,
        revenue: 630000,
        percentage: 19.0,
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_b2c/app.dart';
import 'package:mefali_b2c/features/home/home_screen.dart';
import 'package:mefali_b2c/features/profile/profile_screen.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

void main() {
  testWidgets('MefaliB2cApp renders phone screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2cApp()));
    await tester.pumpAndSettle();

    // L'app demarre sur l'ecran de saisie du telephone (non authentifie).
    expect(find.text('Inscription'), findsOneWidget);
  });

  testWidgets('MefaliB2cApp applies mefali theme and title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2cApp()));
    await tester.pumpAndSettle();

    // Verifie que le MaterialApp est configure avec le bon titre.
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'mefali');
  });

  group('RestaurantCard', () {
    const testRestaurant = RestaurantSummary(
      id: 'a0000000-0000-0000-0000-000000000001',
      name: 'Chez Adjoua',
      status: VendorStatus.open,
      avgRating: 4.3,
      totalRatings: 87,
      deliveryFee: 50000,
    );

    testWidgets('renders restaurant name and delivery fee', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestaurantCard(restaurant: testRestaurant, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Chez Adjoua'), findsOneWidget);
      expect(find.textContaining('500 FCFA'), findsOneWidget);
    });

    testWidgets('renders rating row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestaurantCard(restaurant: testRestaurant, onTap: () {}),
          ),
        ),
      );

      // Rating: "4.3 (87)"
      expect(find.textContaining('4.3'), findsOneWidget);
      expect(find.textContaining('87'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestaurantCard(
              restaurant: testRestaurant,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });
  });

  group('HomeScreen discovery', () {
    final mockRestaurants = [
      const RestaurantSummary(
        id: 'b0000000-0000-0000-0000-000000000001',
        name: 'Maquis du Soleil',
        status: VendorStatus.open,
        avgRating: 0.0,
        totalRatings: 0,
        deliveryFee: 50000,
      ),
    ];

    testWidgets('shows skeleton cards while loading', (tester) async {
      final container = ProviderContainer(
        overrides: [
          restaurantDiscoveryProvider(null).overrideWith(
            (ref) => Future.delayed(const Duration(seconds: 60), () => []),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      container.read(authProvider.notifier).updateUser(
        const User(
          id: '00000000-0000-0000-0000-000000000001',
          phone: '+2250700000000',
          name: 'Test',
          role: UserRole.client,
          status: UserStatus.active,
        ),
      );

      // After first frame (loading state), skeletons are visible
      await tester.pump();
      expect(find.byType(RestaurantCardSkeleton), findsWidgets);
    });

    testWidgets('shows restaurant cards when data loaded', (tester) async {
      final container = ProviderContainer(
        overrides: [
          restaurantDiscoveryProvider(null).overrideWith(
            (ref) async => mockRestaurants,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      container.read(authProvider.notifier).updateUser(
        const User(
          id: '00000000-0000-0000-0000-000000000001',
          phone: '+2250700000000',
          name: 'Test',
          role: UserRole.client,
          status: UserStatus.active,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Maquis du Soleil'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      final container = ProviderContainer(
        overrides: [
          restaurantDiscoveryProvider(null).overrideWith(
            (ref) async => throw Exception('network error'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      container.read(authProvider.notifier).updateUser(
        const User(
          id: '00000000-0000-0000-0000-000000000001',
          phone: '+2250700000000',
          name: 'Test',
          role: UserRole.client,
          status: UserStatus.active,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Impossible de charger les restaurants'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });

  group('ProfileScreen', () {
    testWidgets('displays user name, phone, role, and logout button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      ProviderScope.containerOf(tester.element(find.byType(ProfileScreen)))
          .read(authProvider.notifier)
          .updateUser(
            const User(
              id: '00000000-0000-0000-0000-000000000001',
              phone: '+2250700000000',
              name: 'Koffi',
              role: UserRole.client,
              status: UserStatus.active,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Koffi'), findsOneWidget);
      expect(find.text('+2250700000000'), findsOneWidget);
      expect(find.text('client'), findsOneWidget);
      expect(find.text('Deconnexion'), findsOneWidget);
    });

    testWidgets('shows avatar initial from user name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      ProviderScope.containerOf(tester.element(find.byType(ProfileScreen)))
          .read(authProvider.notifier)
          .updateUser(
            const User(
              id: '00000000-0000-0000-0000-000000000001',
              phone: '+2250700000000',
              name: 'Koffi',
              role: UserRole.client,
              status: UserStatus.active,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
    });
  });
}

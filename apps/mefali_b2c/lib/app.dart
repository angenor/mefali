import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'features/auth/name_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/phone_screen.dart';
import 'features/home/home_screen.dart';
import 'features/order/order_confirmation_screen.dart';
import 'features/order/order_tracking_screen.dart';
import 'features/order/orders_list_screen.dart';
import 'features/restaurant/restaurant_catalogue_screen.dart';
import 'features/profile/change_phone_screen.dart';
import 'features/profile/edit_name_screen.dart';
import 'features/profile/verify_phone_screen.dart';

/// Ecoute les changements d'authentification pour declencher
/// la reevaluation du redirect GoRouter sans recreer le routeur.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _sub = _ref.listen(authProvider, (prev, next) {
      if (prev?.isAuthenticated != next.isAuthenticated) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  bool get isAuthenticated => _ref.read(authProvider).isAuthenticated;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/auth/phone',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuthenticated = notifier.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/phone';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/auth/name',
        builder: (context, state) {
          final data = state.extra as Map<String, String>? ?? {};
          return NameScreen(phone: data['phone'] ?? '', otp: data['otp'] ?? '');
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final restaurant = state.extra as RestaurantSummary;
          return RestaurantCatalogueScreen(
            restaurantId: id,
            restaurant: restaurant,
          );
        },
      ),
      GoRoute(
        path: '/order/confirmation',
        builder: (context, state) {
          final order = state.extra as Order;
          return OrderConfirmationScreen(order: order);
        },
      ),
      GoRoute(
        path: '/order/tracking/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersListScreen(),
      ),
      GoRoute(
        path: '/profile/edit-name',
        builder: (context, state) => const EditNameScreen(),
      ),
      GoRoute(
        path: '/profile/change-phone',
        builder: (context, state) => const ChangePhoneScreen(),
      ),
      GoRoute(
        path: '/profile/verify-phone',
        builder: (context, state) {
          final newPhone = state.extra as String? ?? '';
          return VerifyPhoneScreen(newPhone: newPhone);
        },
      ),
    ],
  );
});

class MefaliB2cApp extends ConsumerWidget {
  const MefaliB2cApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'mefali',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

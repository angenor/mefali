import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'features/auth/otp_screen.dart';
import 'features/auth/phone_screen.dart';
import 'features/catalogue/product_form_screen.dart';
import 'features/demo/demo_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/business_hours_screen.dart';

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
      final isDemoRoute = state.matchedLocation == '/demo';

      // La route demo est accessible sans authentification
      if (isDemoRoute) return null;
      if (isAuthenticated && isAuthRoute) return '/home';
      if (!isAuthenticated && !isAuthRoute) return '/auth/phone';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const B2bPhoneScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return B2bOtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const B2bHomeScreen(),
      ),
      GoRoute(
        path: '/catalogue/add',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/catalogue/edit',
        builder: (context, state) {
          final product = state.extra as Product?;
          return ProductFormScreen(product: product);
        },
      ),
      GoRoute(
        path: '/settings/hours',
        builder: (context, state) => const BusinessHoursScreen(),
      ),
      GoRoute(
        path: '/demo',
        builder: (context, state) => const DemoScreen(),
      ),
    ],
  );
});

class MefaliB2bApp extends ConsumerWidget {
  const MefaliB2bApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'mefali Marchand',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

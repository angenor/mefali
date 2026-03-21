import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_design/mefali_design.dart';

import 'features/auth/phone_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/home/home_screen.dart';
import 'features/kyc/kyc_capture_screen.dart';
import 'features/kyc/pending_drivers_screen.dart';
import 'features/dashboard/admin_shell_screen.dart';
import 'features/dashboard/agent_performance_screen.dart';
import 'features/onboarding/onboarding_wizard_screen.dart';

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

      if (isAuthenticated && isAuthRoute) return '/home';
      if (!isAuthenticated && !isAuthRoute) return '/auth/phone';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const AdminPhoneScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return AdminOtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/kyc',
        builder: (context, state) => const PendingDriversScreen(),
      ),
      GoRoute(
        path: '/kyc/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return KycCaptureScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const AdminShellScreen(),
      ),
      GoRoute(
        path: '/dashboard/performance',
        builder: (context, state) => const AgentPerformanceScreen(),
      ),
      GoRoute(
        path: '/onboarding/new',
        builder: (context, state) => const OnboardingWizardScreen(),
      ),
      GoRoute(
        path: '/onboarding/:merchantId',
        builder: (context, state) {
          final merchantId = state.pathParameters['merchantId']!;
          return OnboardingWizardScreen(merchantId: merchantId);
        },
      ),
    ],
  );
});

class MefaliAdminApp extends ConsumerWidget {
  const MefaliAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'mefali Agent',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

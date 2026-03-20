import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'features/auth/otp_screen.dart';
import 'features/auth/phone_screen.dart';
import 'features/auth/registration_screen.dart';
import 'features/home/home_screen.dart';
import 'features/notification/deep_link_handler.dart';
import 'features/profile/change_phone_screen.dart';
import 'features/profile/edit_name_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/delivery/client_absent_screen.dart';
import 'features/delivery/collection_navigation_screen.dart';
import 'features/delivery/incoming_mission_screen.dart';
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
        path: '/auth/register',
        builder: (context, state) {
          final data = state.extra as Map<String, String>? ?? {};
          return RegistrationScreen(
            phone: data['phone'] ?? '',
            otp: data['otp'] ?? '',
          );
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/delivery/incoming-mission',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return IncomingMissionScreen(missionData: data);
        },
      ),
      GoRoute(
        path: '/delivery/collection-navigation',
        builder: (context, state) {
          final mission = state.extra! as DeliveryMission;
          return CollectionNavigationScreen(mission: mission);
        },
      ),
      GoRoute(
        path: '/delivery/client-absent',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return ClientAbsentScreen(
            deliveryId: data['deliveryId'] as String? ?? '',
            orderId: data['orderId'] as String? ?? '',
            paymentType: data['paymentType'] as String? ?? 'cod',
            deliveryFee: (data['deliveryFee'] as num?)?.toInt() ?? 0,
            customerPhone: data['customerPhone'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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

class MefaliLivreurApp extends ConsumerStatefulWidget {
  const MefaliLivreurApp({super.key});

  @override
  ConsumerState<MefaliLivreurApp> createState() => _MefaliLivreurAppState();
}

class _MefaliLivreurAppState extends ConsumerState<MefaliLivreurApp> {
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _handleInitialDeepLink();
    _listenDeepLinks();
  }

  void _handleInitialDeepLink() {
    final initial = DeepLinkHandler.instance.initialLink;
    if (initial != null) {
      // Delay to allow router to initialize
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processDeepLink(initial);
      });
    }
  }

  void _listenDeepLinks() {
    _deepLinkSub = DeepLinkHandler.instance.linkStream.listen(_processDeepLink);
  }

  void _processDeepLink(Uri uri) {
    final base64Data = DeepLinkHandler.extractMissionData(uri);
    if (base64Data == null) return;

    try {
      final mission = DeliveryMission.fromDeepLink(base64Data);
      final router = ref.read(_routerProvider);
      router.go('/delivery/incoming-mission', extra: mission.toJson());
    } catch (e) {
      debugPrint('Failed to parse deep link mission data: $e');
    }
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'mefali Livreur',
      theme: MefaliTheme.light(),
      darkTheme: MefaliTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

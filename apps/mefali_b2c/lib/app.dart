import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_design/mefali_design.dart';

import 'features/auth/name_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/phone_screen.dart';
import 'features/home/home_screen.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth/phone',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
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

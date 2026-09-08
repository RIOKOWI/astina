import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/router_refresh_notifier.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/profile',
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    final authState = routerRefreshNotifier.state;
    final isLogin = state.matchedLocation == '/login';

    if (authState == null) return null; // Still initializing

    if (!authState.isAuthenticated && !isLogin) {
      return '/login';
    }

    if (authState.isAuthenticated && isLogin) {
      return '/profile';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Dashboard (placeholder)'))),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
);

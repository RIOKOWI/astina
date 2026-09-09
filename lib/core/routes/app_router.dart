import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/router_refresh_notifier.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/finance/presentation/pages/finance_page.dart';
import '../../features/sos/presentation/pages/sos_page.dart';
import '../../features/my/presentation/pages/my_household_page.dart';
import '../../features/residents/presentation/pages/my_resident_page.dart';
import '../../features/residents/presentation/pages/my_document_page.dart';
import '../../features/residents/presentation/pages/residents_page.dart';
import '../../features/residents/presentation/pages/resident_detail_page.dart';
import '../../features/residents/presentation/pages/households_page.dart';
import '../../features/residents/presentation/pages/household_detail_page.dart';

final _restrictedRoutes = {
  '/residents': [UserRole.rt],
  '/households': [UserRole.rt],
  '/users': [UserRole.rt],
  '/activities/create': [UserRole.rt],
  '/inventory': [UserRole.rt],
  '/finance/dues': [UserRole.rt],
  '/finance/payments/pending': [UserRole.bendahara],
  '/complaints/create': [UserRole.warga],
  '/letters/create': [UserRole.warga],
};

UserRole? _getRequiredRole(String path) {
  for (final entry in _restrictedRoutes.entries) {
    if (path == entry.key || path.startsWith('${entry.key}/')) {
      return entry.value.first;
    }
  }
  return null;
}

bool _isRouteAllowed(String path, UserRole currentRole) {
  final allowed = _restrictedRoutes.entries
      .where((e) => path == e.key || path.startsWith('${e.key}/'))
      .expand((e) => e.value)
      .toList();
  return allowed.contains(currentRole);
}

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    final authState = routerRefreshNotifier.state;
    final path = state.matchedLocation;
    final isLogin = path == '/login';

    if (authState == null) return null;

    if (!authState.isAuthenticated && !isLogin) {
      return '/login';
    }

    if (authState.isAuthenticated && isLogin) {
      return '/dashboard';
    }

    final requiredRole = _getRequiredRole(path);
    if (requiredRole != null) {
      final currentRole = switch (authState.user?.primaryRoleCode) {
        'rt' => UserRole.rt,
        'bendahara' => UserRole.bendahara,
        'warga' => UserRole.warga,
        _ => UserRole.unknown,
      };
      if (!_isRouteAllowed(path, currentRole)) {
        return '/dashboard';
      }
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
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/change-password',
      name: 'change-password',
      builder: (context, state) => const ChangePasswordPage(),
    ),
    GoRoute(
      path: '/finance',
      name: 'finance',
      builder: (context, state) => const FinancePage(),
    ),
    GoRoute(
      path: '/sos',
      name: 'sos',
      builder: (context, state) => const SosPage(),
    ),
    GoRoute(
      path: '/my/household',
      name: 'my-household',
      builder: (context, state) => const MyHouseholdPage(),
    ),
    GoRoute(
      path: '/my/resident',
      name: 'my-resident',
      builder: (context, state) => const MyResidentPage(),
    ),
    GoRoute(
      path: '/my/documents',
      name: 'my-documents',
      builder: (context, state) => const MyDocumentPage(),
    ),
    GoRoute(
      path: '/residents',
      name: 'residents',
      builder: (context, state) => const ResidentsPage(),
    ),
    GoRoute(
      path: '/residents/:id',
      name: 'resident-detail',
      builder: (context, state) => ResidentDetailPage(
        residentId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/households',
      name: 'households',
      builder: (context, state) => const HouseholdsPage(),
    ),
    GoRoute(
      path: '/households/:id',
      name: 'household-detail',
      builder: (context, state) => HouseholdDetailPage(
        householdId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
);

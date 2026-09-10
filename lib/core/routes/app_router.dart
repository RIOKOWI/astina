import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/router_refresh_notifier.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/finance/presentation/pages/finance_page.dart';
import '../../features/finance/presentation/pages/transactions_page.dart';
import '../../features/finance/presentation/pages/transaction_form_page.dart';
import '../../features/finance/presentation/pages/pending_payments_page.dart';
import '../../features/finance/presentation/pages/dues_page.dart';
import '../../features/finance/presentation/pages/my_due_bills_page.dart';
import '../../features/finance/presentation/pages/my_payments_page.dart';
import '../../features/finance/presentation/pages/payment_form_page.dart';
import '../../features/sos/presentation/pages/sos_page.dart';
import '../../features/my/presentation/pages/my_household_page.dart';
import '../../features/residents/presentation/pages/my_resident_page.dart';
import '../../features/residents/presentation/pages/my_document_page.dart';
import '../../features/residents/presentation/pages/residents_page.dart';
import '../../features/residents/presentation/pages/resident_detail_page.dart';
import '../../features/residents/presentation/pages/resident_form_page.dart';
import '../../features/residents/presentation/pages/households_page.dart';
import '../../features/residents/presentation/pages/household_detail_page.dart';
import '../../features/residents/presentation/pages/household_form_page.dart';
import '../../features/residents/presentation/pages/account_form_page.dart';
import '../../features/residents/presentation/pages/users_page.dart';
import '../../features/residents/presentation/pages/user_detail_page.dart';
import '../../features/fcm/presentation/pages/notifications_page.dart';
import '../../features/complaints/presentation/pages/complaints_page.dart';
import '../../features/complaints/presentation/pages/complaint_detail_page.dart';
import '../../features/complaints/presentation/pages/complaint_create_page.dart';
import '../../features/residents/presentation/pages/document_viewer_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/inventory/presentation/pages/asset_detail_page.dart';
import '../../features/inventory/presentation/pages/asset_form_page.dart';
import '../../features/inventory/presentation/pages/movement_form_page.dart';
import '../../features/dashboard/presentation/pages/activities_page.dart';
import '../../features/dashboard/presentation/pages/activity_detail_page.dart';
import '../../features/dashboard/presentation/pages/activity_form_page.dart';
import '../../features/dashboard/presentation/pages/attachment_viewer_page.dart';
import '../../features/dashboard/data/models/activity_model.dart';

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
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/complaints',
      name: 'complaints',
      builder: (context, state) => const ComplaintsPage(),
    ),
    GoRoute(
      path: '/complaints/create',
      name: 'complaint-create',
      builder: (context, state) => const ComplaintCreatePage(),
    ),
    GoRoute(
      path: '/complaints/:id',
      name: 'complaint-detail',
      builder: (context, state) => ComplaintDetailPage(
        complaintId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/_document_viewer',
      name: 'document-viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return DocumentViewerPage(
          title: extra['title'] as String,
          fetchBytes: extra['fetchBytes'] as Future<List<int>> Function(),
          fileName: extra['fileName'] as String,
        );
      },
    ),
    GoRoute(
      path: '/inventory',
      name: 'inventory',
      builder: (context, state) => const InventoryPage(),
    ),
    GoRoute(
      path: '/inventory/create',
      name: 'asset-create',
      builder: (context, state) => const AssetFormPage(),
    ),
    GoRoute(
      path: '/inventory/:id',
      name: 'asset-detail',
      builder: (context, state) =>
          AssetDetailPage(assetId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/inventory/:id/edit',
      name: 'asset-edit',
      builder: (context, state) =>
          AssetFormPage(assetId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/inventory/:id/movement',
      name: 'asset-movement',
      builder: (context, state) =>
          MovementFormPage(assetId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/finance',
      name: 'finance',
      builder: (context, state) => const FinancePage(),
    ),
    GoRoute(
      path: '/finance/transactions',
      name: 'finance-transactions',
      builder: (context, state) => const TransactionsPage(),
    ),
    GoRoute(
      path: '/finance/transactions/create',
      name: 'finance-transaction-create',
      builder: (context, state) => const TransactionFormPage(),
    ),
    GoRoute(
      path: '/finance/payments/pending',
      name: 'finance-payments-pending',
      builder: (context, state) => const PendingPaymentsPage(),
    ),
    GoRoute(
      path: '/finance/dues',
      name: 'finance-dues',
      builder: (context, state) => const DuesPage(),
    ),
    GoRoute(
      path: '/finance/my/bills',
      name: 'my-due-bills',
      builder: (context, state) => const MyDueBillsPage(),
    ),
    GoRoute(
      path: '/finance/my/bills/:id/pay',
      name: 'my-payment-form',
      builder: (context, state) {
        final bill = state.extra;
        return PaymentFormPage(bill: bill as dynamic);
      },
    ),
    GoRoute(
      path: '/finance/my/payments',
      name: 'my-payments',
      builder: (context, state) => const MyPaymentsPage(),
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
      path: '/residents/create',
      name: 'resident-create',
      builder: (context, state) => const ResidentFormPage(),
    ),
    GoRoute(
      path: '/residents/:id/edit',
      name: 'resident-edit',
      builder: (context, state) =>
          ResidentFormPage(residentId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/residents/:id',
      name: 'resident-detail',
      builder: (context, state) => ResidentDetailPage(
        residentId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/residents/:id/account',
      name: 'resident-account',
      builder: (context, state) =>
          AccountFormPage(residentId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/households',
      name: 'households',
      builder: (context, state) => const HouseholdsPage(),
    ),
    GoRoute(
      path: '/households/create',
      name: 'household-create',
      builder: (context, state) => const HouseholdFormPage(),
    ),
    GoRoute(
      path: '/households/:id/edit',
      name: 'household-edit',
      builder: (context, state) => HouseholdFormPage(
        householdId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/households/:id',
      name: 'household-detail',
      builder: (context, state) => HouseholdDetailPage(
        householdId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/users',
      name: 'users',
      builder: (context, state) => const UsersPage(),
    ),
    GoRoute(
      path: '/users/:id',
      name: 'user-detail',
      builder: (context, state) =>
          UserDetailPage(userId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/activities',
      name: 'activities',
      builder: (context, state) => const ActivitiesPage(),
    ),
    GoRoute(
      path: '/activities/create',
      name: 'activity-create',
      builder: (context, state) => const ActivityFormPage(),
    ),
    GoRoute(
      path: '/activities/:id',
      name: 'activity-detail',
      builder: (context, state) => ActivityDetailPage(
        activityId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/activities/:id/edit',
      name: 'activity-edit',
      builder: (context, state) =>
          ActivityFormPage(activityId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/activities/:activityId/attachments/:attachmentId',
      builder: (context, state) {
        final attachment = state.extra as ActivityAttachment;
        return AttachmentViewerPage(attachment: attachment);
      },
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
);

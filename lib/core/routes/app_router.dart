import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_account_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/resident_page.dart';
import '../../features/profile/presentation/pages/household_page.dart';
import '../../features/profile/presentation/pages/documents_page.dart';
import '../../features/activity/presentation/pages/activity_list_page.dart';
import '../../features/activity/presentation/pages/activity_detail_page.dart';
import '../../features/notification/presentation/pages/notification_list_page.dart';
import '../../features/complaint/presentation/pages/complaint_list_page.dart';
import '../../features/complaint/presentation/pages/complaint_detail_page.dart';
import '../../features/complaint/presentation/pages/create_complaint_page.dart';
import '../../features/finance/presentation/pages/finance_hub_page.dart';
import '../../features/finance/presentation/pages/due_bills_page.dart';
import '../../features/finance/presentation/pages/payments_page.dart';
import '../../features/finance/presentation/pages/payment_detail_page.dart';
import '../../features/finance/presentation/pages/cash_transparency_page.dart';
import '../../features/finance/presentation/pages/bendahara/bendahara_hub_page.dart';
import '../../features/finance/presentation/pages/bendahara/pending_payments_page.dart';
import '../../features/finance/presentation/pages/bendahara/payment_review_page.dart';
import '../../features/finance/presentation/pages/bendahara/dues_management_page.dart';
import '../../features/finance/presentation/pages/bendahara/expenses_page.dart';
import '../../features/finance/presentation/pages/bendahara/all_payments_page.dart';
import '../../features/sos/presentation/pages/active_sos_page.dart';
import '../../features/sos/presentation/pages/sos_detail_page.dart';
import '../../features/letters/presentation/pages/letter_hub_page.dart';
import '../../features/letters/presentation/pages/my_letters_page.dart';
import '../../features/letters/presentation/pages/create_letter_page.dart';
import '../../features/letters/presentation/pages/letter_detail_page.dart';
import '../../features/letters/presentation/pages/rt/pending_letters_page.dart';
import '../../features/letters/presentation/pages/rt/letter_review_page.dart';
import '../../features/rt_admin/presentation/pages/rt_admin_hub_page.dart';
import '../../features/rt_admin/presentation/pages/resident_list_page.dart';
import '../../features/rt_admin/presentation/pages/resident_detail_page.dart';
import '../../features/rt_admin/presentation/pages/resident_create_page.dart';
import '../../features/rt_admin/presentation/pages/resident_edit_page.dart';
import '../../features/rt_admin/presentation/pages/household_list_page.dart';
import '../../features/rt_admin/presentation/pages/household_detail_page.dart';
import '../../features/rt_admin/presentation/pages/household_create_page.dart';
import '../../features/rt_admin/presentation/pages/household_edit_page.dart';
import '../../features/rt_admin/presentation/pages/user_list_page.dart';
import '../../features/rt_admin/presentation/pages/user_detail_page.dart';
import '../../features/inventory/presentation/pages/inventory_hub_page.dart';
import '../../features/inventory/presentation/pages/asset_detail_page.dart';
import '../../features/inventory/presentation/pages/create_asset_page.dart';
import '../../features/inventory/presentation/pages/asset_movements_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../services/router_refresh_notifier.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    final isAuthenticated =
        routerRefreshNotifier.state?.isAuthenticated ?? false;
    final isOnLogin = state.matchedLocation == '/login';

    if (!isAuthenticated && !isOnLogin) return '/login';
    if (isAuthenticated && isOnLogin) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/activities',
      builder: (context, state) => const ActivityListPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ActivityDetailPage(activityId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationListPage(),
    ),
    GoRoute(
      path: '/complaints',
      builder: (context, state) => const ComplaintListPage(),
      routes: [
        GoRoute(
          path: 'create',
          builder: (context, state) => const CreateComplaintPage(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ComplaintDetailPage(complaintId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/finance',
      builder: (context, state) => const FinanceHubPage(),
      routes: [
        GoRoute(
          path: 'due-bills',
          builder: (context, state) => const DueBillsPage(),
        ),
        GoRoute(
          path: 'payments',
          builder: (context, state) => const PaymentsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return PaymentDetailPage(paymentId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'cash',
          builder: (context, state) => const CashTransparencyPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/bendahara',
      builder: (context, state) => const BendaharaHubPage(),
      routes: [
        GoRoute(
          path: 'pending',
          builder: (context, state) => const PendingPaymentsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return PaymentReviewPage(paymentId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'payments',
          builder: (context, state) => const AllPaymentsPage(),
        ),
        GoRoute(
          path: 'dues',
          builder: (context, state) => const DuesManagementPage(),
        ),
        GoRoute(
          path: 'expenses',
          builder: (context, state) => const ExpensesPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/sos',
      builder: (context, state) => const ActiveSosPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return SosDetailPage(sosId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/letters',
      builder: (context, state) => const LetterHubPage(),
      routes: [
        GoRoute(path: 'my', builder: (context, state) => const MyLettersPage()),
        GoRoute(
          path: 'create/:typeId',
          builder: (context, state) {
            final typeId = int.parse(state.pathParameters['typeId']!);
            return CreateLetterPage(letterTypeId: typeId);
          },
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return LetterDetailPage(letterId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/letters/rt',
      builder: (context, state) => const PendingLettersPage(),
      routes: [
        GoRoute(
          path: 'review/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return LetterReviewPage(letterId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/rt-admin',
      builder: (context, state) => const RtAdminHubPage(),
      routes: [
        GoRoute(
          path: 'residents',
          builder: (context, state) => const ResidentListPage(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const ResidentCreatePage(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return ResidentDetailPage(residentId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return ResidentEditPage(residentId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'households',
          builder: (context, state) => const HouseholdListPage(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const HouseholdCreatePage(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return HouseholdDetailPage(householdId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return HouseholdEditPage(householdId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const UserListPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return UserDetailPage(userId: id);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryHubPage(),
      routes: [
        GoRoute(
          path: 'create',
          builder: (context, state) => const CreateAssetPage(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return AssetDetailPage(assetId: id);
          },
          routes: [
            GoRoute(
              path: 'movements',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return AssetMovementsPage(assetId: id);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => const EditAccountPage(),
        ),
        GoRoute(
          path: 'change-password',
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: 'resident',
          builder: (context, state) => const ResidentPage(),
        ),
        GoRoute(
          path: 'household',
          builder: (context, state) => const HouseholdPage(),
        ),
        GoRoute(
          path: 'documents',
          builder: (context, state) => const DocumentsPage(),
        ),
      ],
    ),
  ],
);

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../activity/providers/activity_provider.dart';
import '../../../finance/providers/finance_provider.dart';
import '../../../finance/data/models/finance_summary_model.dart';
import '../../../finance/data/models/due_bill_model.dart';
import '../../../sos/presentation/widgets/sos_fab.dart';

const _dashboardMenus = <DashboardMenuItem>[
  // === WARGA ===
  DashboardMenuItem(
    title: 'Aktivitas',
    icon: Icons.campaign_outlined,
    color: Colors.purple,
    route: '/activities',
    allowedRoles: {'warga', 'rt', 'bendahara'},
  ),
  DashboardMenuItem(
    title: 'Surat',
    icon: Icons.mail_outline,
    color: AppColors.primary,
    route: '/letters',
    allowedRoles: {'warga', 'rt'},
  ),
  DashboardMenuItem(
    title: 'Iuran',
    icon: Icons.account_balance_wallet_outlined,
    color: AppColors.success,
    route: '/finance/due-bills',
    allowedRoles: {'warga', 'rt', 'bendahara'},
  ),
  DashboardMenuItem(
    title: 'Kas RT',
    icon: Icons.pie_chart_outline,
    color: AppColors.warning,
    route: '/finance/cash',
    allowedRoles: {'warga', 'rt', 'bendahara'},
  ),
  DashboardMenuItem(
    title: 'Pengaduan',
    icon: Icons.warning_amber_outlined,
    color: AppColors.error,
    route: '/complaints',
    allowedRoles: {'warga', 'rt'},
  ),
  DashboardMenuItem(
    title: 'SOS',
    icon: Icons.sos,
    color: Colors.red,
    route: '/sos',
    allowedRoles: {'warga', 'rt'},
  ),
  DashboardMenuItem(
    title: 'Keluarga',
    icon: Icons.family_restroom,
    color: Colors.teal,
    route: '/profile/household',
    allowedRoles: {'warga'},
  ),
  DashboardMenuItem(
    title: 'Dokumen',
    icon: Icons.folder_outlined,
    color: Colors.brown,
    route: '/profile/documents',
    allowedRoles: {'warga'},
  ),
  // === RT ===
  DashboardMenuItem(
    title: 'Warga',
    icon: Icons.people_outline,
    color: AppColors.primary,
    route: '/rt-admin/residents',
    allowedRoles: {'rt'},
  ),
  DashboardMenuItem(
    title: 'Keluarga',
    icon: Icons.home_work_outlined,
    color: Colors.teal,
    route: '/rt-admin/households',
    allowedRoles: {'rt'},
  ),
  DashboardMenuItem(
    title: 'Akun',
    icon: Icons.manage_accounts_outlined,
    color: Colors.blueGrey,
    route: '/rt-admin/users',
    allowedRoles: {'rt'},
  ),
  DashboardMenuItem(
    title: 'Surat Masuk',
    icon: Icons.inbox_outlined,
    color: AppColors.primary,
    route: '/letters/rt',
    allowedRoles: {'rt'},
  ),
  DashboardMenuItem(
    title: 'Inventory',
    icon: Icons.inventory_2_outlined,
    color: Colors.orange,
    route: '/inventory',
    allowedRoles: {'rt'},
  ),
  DashboardMenuItem(
    title: 'Keuangan',
    icon: Icons.account_balance,
    color: AppColors.warning,
    route: '/bendahara/expenses',
    allowedRoles: {'rt'},
  ),
  // === BENDAHARA ===
  DashboardMenuItem(
    title: 'Verifikasi',
    icon: Icons.verified_outlined,
    color: AppColors.primary,
    route: '/bendahara/pending',
    allowedRoles: {'bendahara'},
  ),
  DashboardMenuItem(
    title: 'Kas',
    icon: Icons.account_balance_wallet,
    color: AppColors.warning,
    route: '/bendahara',
    allowedRoles: {'bendahara'},
  ),
  DashboardMenuItem(
    title: 'Transaksi',
    icon: Icons.swap_horiz,
    color: Colors.green,
    route: '/bendahara/payments',
    allowedRoles: {'bendahara'},
  ),
  // === COMMON ===
  DashboardMenuItem(
    title: 'Profil',
    icon: Icons.person_outline,
    color: Colors.grey,
    route: '/profile',
    allowedRoles: {'warga', 'rt', 'bendahara'},
  ),
  DashboardMenuItem(
    title: 'Notifikasi',
    icon: Icons.notifications_outlined,
    color: Colors.amber,
    route: '/notifications',
    allowedRoles: {'warga', 'rt', 'bendahara'},
  ),
];

class DashboardMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final Set<String> allowedRoles;

  const DashboardMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    required this.allowedRoles,
  });

  bool isVisibleFor(UserModel? user) {
    if (user == null) return false;
    return allowedRoles.any((role) => user.hasRole(role));
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Keluar aplikasi?'),
        content: const Text('Apakah Anda yakin ingin keluar dari ASTINA?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;

    if (kDebugMode) {
      developer.log(
        'Dashboard: roles=${user?.roles.map((r) => r.code).toList() ?? []}',
        name: 'Dashboard',
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activitiesProvider);
            ref.invalidate(financeSummaryProvider);
            ref.invalidate(dueBillsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildGreeting(
                  user?.resident?.fullName ?? user?.phone ?? 'Warga',
                  user,
                ),
              ),
              SliverToBoxAdapter(child: _QuickActionsSection(user: user)),
              const SliverToBoxAdapter(child: _ActivitiesSection()),
              const SliverToBoxAdapter(child: _FinanceSummarySection()),
              const SliverToBoxAdapter(child: _DueBillsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
        floatingActionButton: const SosFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildGreeting(String name, UserModel? user) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Selamat Pagi';
    } else if (hour < 15) {
      timeGreeting = 'Selamat Siang';
    } else if (hour < 18) {
      timeGreeting = 'Selamat Sore';
    } else {
      timeGreeting = 'Selamat Malam';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeGreeting,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (user != null && user.roles.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.roles
                  .map((r) {
                    if (r.code == 'warga') return 'Warga';
                    if (r.code == 'rt') return 'RT';
                    if (r.code == 'bendahara') return 'Bendahara';
                    return r.name;
                  })
                  .join(' • '),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'RT 005 — Semoga harimu menyenangkan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final UserModel? user;

  const _QuickActionsSection({this.user});

  @override
  Widget build(BuildContext context) {
    final visibleMenus = _dashboardMenus
        .where((m) => m.isVisibleFor(user))
        .toList();

    if (kDebugMode) {
      developer.log(
        'Dashboard: visible menu count=${visibleMenus.length}',
        name: 'Dashboard',
      );
    }

    if (visibleMenus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Layanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: visibleMenus.map((menu) {
              return _QuickActionCard(
                icon: menu.icon,
                label: menu.title,
                color: menu.color,
                onTap: () => context.go(menu.route),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitiesSection extends ConsumerWidget {
  const _ActivitiesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/activities'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dark.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: activitiesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Gagal memuat aktivitas',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ),
              data: (activities) {
                if (activities.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Belum ada aktivitas',
                        style: TextStyle(color: AppColors.grey, fontSize: 13),
                      ),
                    ),
                  );
                }
                return Column(
                  children: activities.take(3).map<Widget>((activity) {
                    return ListTile(
                      onTap: () => context.push('/activities/${activity.id}'),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.event,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        activity.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        activity.description ?? activity.statusLabel,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.grey,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceSummarySection extends ConsumerWidget {
  const _FinanceSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financeSummaryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Kas RT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/bendahara'),
                child: const Text('Detail'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: summaryAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
              error: (e, _) => const Text(
                'Gagal memuat',
                style: TextStyle(color: Colors.white),
              ),
              data: (FinanceSummaryModel summary) => Column(
                children: [
                  const Text(
                    'Saldo Kas',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.formattedBalance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _FinanceStatItem(
                          label: 'Pemasukan Bulan Ini',
                          amount: summary.formatAmount(summary.incomeThisMonth),
                          icon: Icons.arrow_downward,
                          iconColor: Colors.greenAccent,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        child: _FinanceStatItem(
                          label: 'Pengeluaran Bulan Ini',
                          amount: summary.formatAmount(
                            summary.expenseThisMonth,
                          ),
                          icon: Icons.arrow_upward,
                          iconColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceStatItem extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;

  const _FinanceStatItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DueBillsSection extends ConsumerWidget {
  const _DueBillsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueBillsAsync = ref.watch(dueBillsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tagihan Saya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/finance/due-bills'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dark.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: dueBillsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Gagal memuat tagihan',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              data: (List<DueBillModel> bills) {
                if (bills.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tidak ada tagihan aktif',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: bills.take(2).map((bill) {
                    return ListTile(
                      onTap: () => context.go('/finance/due-bills'),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        bill.due?.name ?? 'Iuran',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Jatuh tempo: ${bill.dueDate}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        _formatAmount(bill.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.error,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }
}

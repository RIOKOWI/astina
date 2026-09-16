import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../sos/providers/sos_provider.dart';
import '../../../sos/services/sos_audio_service.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/activity_model.dart';
import '../../providers/activity_provider.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../providers/dashboard_summary_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final user = ref.watch(authProvider).user;
    final menuItems = _getMenuItems(role);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // At dashboard root, back button exits app (default behavior)
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Astina Smart Mobile'),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(context, ref, user, menuItems),
        body: _DashboardHome(user: user, role: role),
        floatingActionButton: FloatingActionButton.large(
          heroTag: 'sos_fab',
          backgroundColor: AppColors.error,
          onPressed: () => _onSosPressed(context, ref),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Lottie.asset(
              'assets/lottie/sos-animation.json',
              repeat: true,
            ),
          ),
        ),
      ),
    );
  }

  List<MenuItemModel> _getMenuItems(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return MenuConfig.rt;
      case UserRole.bendahara:
        return MenuConfig.bendahara;
      case UserRole.warga:
      case UserRole.unknown:
        return MenuConfig.warga;
    }
  }

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    List<MenuItemModel> items,
  ) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        user?.resident?.fullName
                                .substring(0, 1)
                                .toUpperCase() ??
                            'A',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.resident?.fullName ?? 'Warga',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (user?.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user!.phone!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  if (user?.roles.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: user!.roles.map<Widget>((role) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isActive = item.route == '/dashboard';
                  return _buildDrawerItem(
                    context,
                    icon: item.icon,
                    label: item.label,
                    isActive: isActive,
                    onTap: () {
                      Navigator.pop(context);
                      if (!isActive) context.push(item.route);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    Color? color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppColors.primary;
    final defaultColor = AppColors.dark.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? activeColor : defaultColor,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeColor : AppColors.dark,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        onTap: onTap,
      ),
    );
  }

  Future<void> _onSosPressed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8),
            Text('Konfirmasi SOS'),
          ],
        ),
        content: const Text(
          'Kirim peringatan SOS darurat ke semua warga?\n'
          'Lokasi Anda akan dikirimkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kirim SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('GPS nonaktif. Aktifkan untuk mengirim SOS.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Izin lokasi ditolak permanen.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Mengirim SOS...'),
        backgroundColor: AppColors.dark,
      ),
    );

    HapticFeedback.heavyImpact();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final alert = await ref
          .read(sosNotifierProvider.notifier)
          .triggerSos(
            latitude: position.latitude,
            longitude: position.longitude,
          );

      SosAudioService.instance.playSiren();

      messenger.showSnackBar(
        SnackBar(
          content: Text('SOS terkirim! oleh ${alert.triggeredBy.name}.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
      if (context.mounted) context.go('/sos/${alert.id}');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim SOS: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _DashboardHome extends ConsumerStatefulWidget {
  const _DashboardHome({required this.user, required this.role});

  final dynamic user;
  final UserRole role;

  @override
  ConsumerState<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<_DashboardHome> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activitiesListProvider.notifier).load(status: 'published');
      ref.read(dashboardSummaryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final actState = ref.watch(activitiesListProvider);
    final summary = ref.watch(dashboardSummaryProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(activitiesListProvider.notifier).load(status: 'published');
          await ref.read(dashboardSummaryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang,',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.dark.withValues(alpha: 0.58),
                ),
              ),
              Text(
                widget.user?.resident?.fullName ?? 'Warga',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              if (widget.user?.roles.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.user!.roles.map<Widget>((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        r.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 28),
              _buildRoleSpecificSummary(widget.role, summary),
              const SizedBox(height: 24),
              _buildActivitiesSection(actState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(ActivitiesListState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/activities'),
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Gagal memuat aktivitas',
                    style: TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(activitiesListProvider.notifier)
                      .load(status: 'published'),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          )
        else if (state.activities.isEmpty && !state.isLoading)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dark.withValues(alpha: 0.05)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.event_outlined, size: 36, color: AppColors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada aktivitas',
                    style: TextStyle(fontSize: 14, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.activities.length > 5
                ? 5
                : state.activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = state.activities[index];
              return _buildActivityCard(a);
            },
          ),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return GestureDetector(
      onTap: () => context.push('/activities/${activity.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (activity.location != null) ...[
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppColors.dark.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                activity.location!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.dark.withValues(alpha: 0.45),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (activity.startAt != null) ...[
                            if (activity.location != null)
                              const SizedBox(width: 8),
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: AppColors.dark.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatDate(activity.startAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.dark.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.dark.withValues(alpha: 0.30),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildRoleSpecificSummary(UserRole role, DashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: _summaryItems(
            role,
            summary,
          ).map((e) => _buildSummaryCard(e.$1, e.$2, e.$3)).toList(),
        ),
      ],
    );
  }

  List<(IconData, String, String)> _summaryItems(
    UserRole role,
    DashboardSummary summary,
  ) {
    switch (role) {
      case UserRole.rt:
        return [
          (
            Icons.mail_outlined,
            'Surat Pending',
            '${summary.letterPendingCount}',
          ),
          (
            Icons.report_outlined,
            'Pengaduan',
            '${summary.complaintPendingCount}',
          ),
          (
            Icons.warning_amber_outlined,
            'SOS Aktif',
            '${summary.sosActiveCount}',
          ),
          (Icons.campaign_outlined, 'Aktivitas', '${summary.activityCount}'),
        ];
      case UserRole.bendahara:
        return [
          (
            Icons.payments_outlined,
            'Pembayaran Pending',
            '${summary.paymentPendingCount}',
          ),
          (
            Icons.account_balance_wallet_outlined,
            'Saldo Kas',
            'Rp ${_formatRupiah(summary.cashBalance)}',
          ),
        ];
      case UserRole.warga:
      case UserRole.unknown:
        return [
          (Icons.campaign_outlined, 'Aktivitas RT', '${summary.activityCount}'),
          (
            Icons.account_balance_wallet_outlined,
            'Tagihan Saya',
            'Rp ${_formatRupiah(summary.myDueBillAmount)}',
          ),
        ];
    }
  }

  String _formatRupiah(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return '$amount';
  }

  Widget _buildSummaryCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../sos/providers/sos_provider.dart';
import '../../../sos/services/sos_audio_service.dart';
import '../../data/models/menu_item_model.dart';

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
          child: const Icon(Icons.warning_rounded, size: 36, color: Colors.white),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDrawerItem(
                context,
                icon: Icons.logout,
                label: 'Keluar',
                isActive: false,
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, ref);
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
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

      final alert = await ref.read(sosNotifierProvider.notifier).triggerSos(
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

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome({required this.user, required this.role});

  final dynamic user;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
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
              user?.resident?.fullName ?? 'Warga',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            if (user?.roles.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: user!.roles.map<Widget>((r) {
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
            _buildRoleSpecificSummary(role),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificSummary(UserRole role) {
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
          ).map((e) => _buildSummaryCard(e.$1, e.$2, e.$3)).toList(),
        ),
      ],
    );
  }

  List<(IconData, String, String)> _summaryItems(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return [
          (Icons.mail_outlined, 'Surat Pending', '0'),
          (Icons.report_outlined, 'Pengaduan', '0'),
          (Icons.warning_amber_outlined, 'SOS Aktif', '0'),
          (Icons.campaign_outlined, 'Aktivitas', '0'),
        ];
      case UserRole.bendahara:
        return [
          (Icons.payments_outlined, 'Pembayaran Pending', '0'),
          (Icons.account_balance_wallet_outlined, 'Saldo Kas', 'Rp 0'),
        ];
      case UserRole.warga:
      case UserRole.unknown:
        return [
          (Icons.campaign_outlined, 'Aktivitas RT', '0'),
          (Icons.account_balance_wallet_outlined, 'Tagihan Saya', 'Rp 0'),
        ];
    }
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

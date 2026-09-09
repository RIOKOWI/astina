import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/sos_provider.dart';

class SosPage extends ConsumerWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final alertsAsync = ref.watch(sosActiveAlertsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('SOS Darurat'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sosActiveAlertsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (role == UserRole.warga || role == UserRole.rt) ...[
                _buildPanicSection(context, ref),
                const SizedBox(height: 24),
              ],
              const Text(
                'SOS Aktif',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return _buildEmptyState();
                  }
                  return Column(
                    children: alerts
                        .map((a) => _buildAlertCard(context, a))
                        .toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _buildErrorCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanicSection(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showPanicDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_rounded, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'TOMBOL SOS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan dan tahan untuk memanggil bantuan',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPanicDialog(BuildContext context, WidgetRef ref) {
    showDialog(
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
          'Kirim peringatan SOS darurat ke semua warga? '
          'Lokasi Anda akan dikirimkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS dikirim!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Kirim SOS'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, dynamic alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 14, color: AppColors.error),
                    SizedBox(width: 4),
                    Text(
                      'AKTIF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(alert.triggeredAt),
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.triggeredBy.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          if (alert.household != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert.household!.address,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (alert.location.text != null) ...[
            const SizedBox(height: 2),
            Text(
              alert.location.text!,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
          SizedBox(height: 12),
          Text(
            'Tidak ada SOS aktif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Semua warga dalam kondisi aman',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gagal memuat data SOS',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    }
    return '${diff.inDays}h lalu';
  }
}

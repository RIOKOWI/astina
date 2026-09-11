import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/sos_alert_model.dart';
import '../../providers/sos_provider.dart';
import '../../services/sos_audio_service.dart';

class SosDetailPage extends ConsumerWidget {
  final int sosId;

  const SosDetailPage({super.key, required this.sosId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sosAlertDetailProvider(sosId));
    final role = ref.watch(currentUserRoleProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail SOS'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: detailAsync.when(
        data: (alert) => _buildContent(context, ref, alert, role),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SosAlertModel alert,
    UserRole role,
  ) {
    final isRT = role == UserRole.rt;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sosAlertDetailProvider(sosId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(alert),
            const SizedBox(height: 16),
            _buildLocationCard(alert),
            if (alert.household != null) ...[
              const SizedBox(height: 16),
              _buildHouseholdCard(alert.household!),
            ],
            if (alert.responses.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildResponsesCard(alert),
            ],
            if (isRT && alert.isActive) ...[
              const SizedBox(height: 24),
              _buildResolveButton(context, ref, alert),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(SosAlertModel alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: alert.isActive
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      alert.isActive ? Icons.warning : Icons.check_circle,
                      size: 14,
                      color: alert.isActive
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.isActive ? 'AKTIF' : 'RESOLVED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: alert.isActive
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            alert.triggeredBy.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.access_time,
            'Dipicu',
            _formatDateTime(alert.triggeredAt),
          ),
          if (alert.resolvedAt != null) ...[
            const SizedBox(height: 6),
            _infoRow(
              Icons.check_circle,
              'Diselesaikan',
              _formatDateTime(alert.resolvedAt!),
            ),
          ],
          if (alert.resolvedBy != null) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.person, 'Oleh', alert.resolvedBy!.name),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(SosAlertModel alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Lokasi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (alert.location.text != null) ...[
            Text(
              alert.location.text!,
              style: const TextStyle(fontSize: 14, color: AppColors.dark),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '${alert.location.latitude.toStringAsFixed(6)}, ${alert.location.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard(SosHousehold household) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Alamat Rumah',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            household.address,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
          if (household.rt != null || household.rw != null) ...[
            const SizedBox(height: 4),
            Text(
              'RT ${household.rt} / RW ${household.rw}${household.postalCode != null ? ' - ${household.postalCode}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsesCard(SosAlertModel alert) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Respons (${alert.responses.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 12),
        ...alert.responses.map((r) => _buildResponseTile(r)),
      ],
    );
  }

  Widget _buildResponseTile(SosResponse response) {
    final isComing = response.response == 'coming';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isComing
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.grey.withValues(alpha: 0.1),
            child: Icon(
              isComing ? Icons.directions_run : Icons.close,
              size: 16,
              color: isComing ? AppColors.success : AppColors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.user.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  isComing ? 'Segera datang' : 'Tidak bisa',
                  style: TextStyle(
                    fontSize: 11,
                    color: isComing ? AppColors.success : AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(response.respondedAt),
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResolveButton(
    BuildContext context,
    WidgetRef ref,
    SosAlertModel alert,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _confirmResolve(context, ref, alert.id),
        child: const Text(
          'SELESAIKAN SOS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _confirmResolve(BuildContext context, WidgetRef ref, int alertId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Selesaikan SOS'),
          ],
        ),
        content: const Text(
          'Tandai SOS ini sebagai sudah diselesaikan? '
          'Sirene akan berhenti berbunyi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _resolveAlert(context, ref, alertId);
            },
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveAlert(
    BuildContext context,
    WidgetRef ref,
    int alertId,
  ) async {
    try {
      final ds = ref.read(sosRemoteDataSourceProvider);
      await ds.resolveAlert(alertId);
      SosAudioService.instance.stopSiren();
      ref.invalidate(sosActiveAlertsProvider);
      ref.invalidate(sosAlertDetailProvider(alertId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS berhasil diselesaikan.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/sos_provider.dart';

class SosDetailPage extends ConsumerWidget {
  final int sosId;

  const SosDetailPage({super.key, required this.sosId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sosDetailProvider(sosId));
    final stateAsync = ref.watch(sosNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        title: const Text('SOS Detail'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alert) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(alert),
              const SizedBox(height: 16),
              _buildSenderInfo(alert),
              const SizedBox(height: 16),
              if (alert.mapUrl != null) ...[
                _buildMapCard(alert),
                const SizedBox(height: 16),
              ],
              _buildResponses(alert),
              const SizedBox(height: 16),
              if (!alert.isResolved)
                _buildActionButtons(context, ref, alert, stateAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'SOS DARURAT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${alert.formattedDate} ${alert.formattedTime}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderInfo(alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.sender?.name ?? 'Warga',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (alert.sender?.phone != null)
                      Text(
                        alert.sender!.phone!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (alert.sender?.address != null &&
              alert.sender!.address!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 18, color: AppColors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.sender!.address!,
                    style: AppTextStyles.body.copyWith(color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ],
          if (alert.locationText != null && alert.locationText!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.pin_drop, size: 18, color: AppColors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.locationText!,
                    style: AppTextStyles.body.copyWith(color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapCard(alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Lokasi',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(alert.mapUrl!);
                if (await canLaunchUrl(uri))
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka di Google Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponses(alert) {
    final responders = alert.responses.where((r) => r.isComing).toList();
    final decliners = alert.responses.where((r) => r.isDecline).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respons',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (alert.responses.isEmpty)
            Text(
              'Belum ada respons',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            )
          else ...[
            if (responders.isNotEmpty) ...[
              Text(
                '${responders.length} Menuju Lokasi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...responders.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r.responderName ?? 'Warga',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (decliners.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${decliners.length} Tidak Bisa',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    alert,
    AsyncValue<SosState> stateAsync,
  ) {
    final isSubmitting = stateAsync.valueOrNull?.isSending ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final success = await ref
                          .read(sosNotifierProvider.notifier)
                          .respondToSos(alert.id, true);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('T Anda sedang menuju lokasi'),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.directions_run),
              label: const Text('Saya Menuju Lokasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      await ref
                          .read(sosNotifierProvider.notifier)
                          .respondToSos(alert.id, false);
                      if (context.mounted) Navigator.pop(context);
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.grey,
                side: BorderSide(color: AppColors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tidak Bisa Membantu'),
            ),
          ),
        ],
      ),
    );
  }
}

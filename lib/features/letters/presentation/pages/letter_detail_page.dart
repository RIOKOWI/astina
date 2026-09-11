import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/letter_provider.dart';

class LetterDetailPage extends ConsumerWidget {
  final int letterId;

  const LetterDetailPage({super.key, required this.letterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letterAsync = ref.watch(letterDetailProvider(letterId));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Surat'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: letterAsync.when(
        data: (letter) => _buildContent(context, ref, letter),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic letter) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(letterDetailProvider(letterId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(letter),
            const SizedBox(height: 20),
            _buildInfoCard('Informasi Surat', [
              _infoRow('No. Referensi', letter.referenceNo),
              _infoRow('Jenis', letter.letterType.name),
              if (letter.purpose != null)
                _infoRow('Keperluan', letter.purpose!),
              _infoRow('Status', _statusLabel(letter.status)),
              if (letter.submittedAt != null)
                _infoRow('Diajukan', _formatDateTime(letter.submittedAt!)),
              if (letter.approvedAt != null)
                _infoRow('Disetujui', _formatDateTime(letter.approvedAt!)),
              if (letter.rejectionReason != null)
                _infoRow('Alasan Penolakan', letter.rejectionReason!),
            ]),
            if (letter.fieldValues.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Isi Surat', [
                for (final fv in letter.fieldValues)
                  _infoRow(fv.label, fv.value ?? '-'),
              ]),
            ],
            if (letter.approvals.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Riwayat Approval', [
                for (final approval in letter.approvals) _approvalRow(approval),
              ]),
            ],
            if (letter.documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Dokumen', [
                for (final doc in letter.documents) _docRow(context, ref, doc),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic letter) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _statusColor(letter.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.mail_outlined,
              color: _statusColor(letter.status),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  letter.letterType.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(letter.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel(letter.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(letter.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
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
      ),
    );
  }

  Widget _approvalRow(dynamic approval) {
    final actionColor = approval.action == 'approved'
        ? AppColors.success
        : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            approval.action == 'approved' ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: actionColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${approval.action == 'approved' ? 'Disetujui' : 'Ditolak'} oleh ${approval.approver.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  _formatDateTime(approval.actedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docRow(BuildContext context, WidgetRef ref, dynamic doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              doc.fileName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.push(
                '/_document_viewer',
                extra: {
                  'title': doc.fileName,
                  'fetchBytes': () => ref
                      .read(letterRemoteDataSourceProvider)
                      .downloadDocument(letterId),
                  'fileName': doc.fileName,
                },
              );
            },
            child: const Text('Unduh'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.primary;
      case 'approved':
        return Colors.orange;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/letter_provider.dart';

class LetterDetailPage extends ConsumerStatefulWidget {
  final int letterId;

  const LetterDetailPage({super.key, required this.letterId});

  @override
  ConsumerState<LetterDetailPage> createState() => _LetterDetailPageState();
}

class _LetterDetailPageState extends ConsumerState<LetterDetailPage> {
  final Set<int> _downloadingDocs = {};

  Future<void> _downloadDoc(int docIndex) async {
    if (_downloadingDocs.contains(docIndex)) return;
    setState(() => _downloadingDocs.add(docIndex));

    final bytes = await ref
        .read(letterNotifierProvider.notifier)
        .downloadDocument(widget.letterId);

    if (!mounted) return;
    setState(() => _downloadingDocs.remove(docIndex));

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunduh dokumen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/surat_${widget.letterId}_$docIndex.docx',
      );
      await file.writeAsBytes(bytes);
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka dokumen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(letterDetailProvider(widget.letterId));

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Detail Surat'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (letter) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusHeader(letter),
              const SizedBox(height: 16),
              _buildInfoCard(letter),
              const SizedBox(height: 16),
              if (letter.fieldValues != null &&
                  letter.fieldValues!.isNotEmpty) ...[
                _buildFieldValuesCard(letter),
                const SizedBox(height: 16),
              ],
              if (letter.purpose != null && letter.purpose!.isNotEmpty) ...[
                _buildPurposeCard(letter),
                const SizedBox(height: 16),
              ],
              if (letter.documents != null && letter.documents!.isNotEmpty)
                _buildDocumentsCard(context, letter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(letter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _statusColor(letter.status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(_statusIcon(letter.status), color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            letter.statusLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            letter.referenceNo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${letter.formattedDate} ${letter.formattedTime}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(letter) {
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
          Text('Jenis Surat', style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            letter.letterType?.name ?? '-',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const Divider(height: 24),
          Text('Diajukan', style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            letter.resident?.name ?? '-',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (letter.resident?.address != null) ...[
            const SizedBox(height: 2),
            Text(letter.resident!.address!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldValuesCard(letter) {
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
            'Isi Data',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...letter.fieldValues!.map<Widget>(
            (fv) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(fv.label, style: AppTextStyles.bodySmall),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(fv.value, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeCard(letter) {
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
            'Tujuan',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(letter.purpose!, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context, letter) {
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
            'Dokumen',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...letter.documents!.asMap().entries.map<Widget>((entry) {
            final docIndex = entry.key;
            final doc = entry.value;
            final isDownloading = _downloadingDocs.contains(docIndex);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: isDownloading ? null : () => _downloadDoc(docIndex),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDownloading
                            ? Icons.hourglass_empty
                            : Icons.picture_as_pdf,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fileName,
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              doc.fileSizeFormatted,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (isDownloading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.download, color: AppColors.grey, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.warning;
      case 'approved':
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.hourglass_empty;
      case 'approved':
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }
}

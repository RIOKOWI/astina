import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../data/models/document_model.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Dokumen'),
      ),
      body: docsAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) {
          final ktp = docs.where((d) => d.type.toLowerCase() == 'ktp').toList();
          final kk = docs.where((d) => d.type.toLowerCase() == 'kk').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DocumentCard(
                  type: 'KTP',
                  description: 'Kartu Tanda Penduduk',
                  icon: Icons.badge_outlined,
                  documents: ktp,
                  onUpload: () => _pickAndUpload(context, ref, 'ktp'),
                ),
                const SizedBox(height: 16),
                _DocumentCard(
                  type: 'KK',
                  description: 'Kartu Keluarga',
                  icon: Icons.family_restroom_outlined,
                  documents: kk,
                  onUpload: () => _pickAndUpload(context, ref, 'kk'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Skeletonizer(
        child: Column(
          children: List.generate(
            2,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    if (kDebugMode)
      developer.log('Pick file for $type upload', name: 'DocumentsPage');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload $type: Implement image picker di sini')),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String type;
  final String description;
  final IconData icon;
  final List<DocumentModel> documents;
  final VoidCallback onUpload;

  const _DocumentCard({
    required this.type,
    required this.description,
    required this.icon,
    required this.documents,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final latestDoc = documents.isNotEmpty ? documents.first : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (latestDoc != null) ...[
                  _buildDocStatus(latestDoc),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      latestDoc != null ? 'Ganti Dokumen' : 'Upload $type',
                    ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDocStatus(DocumentModel doc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            doc.status == 'verified'
                ? Icons.check_circle
                : Icons.hourglass_empty,
            color: doc.status == 'verified' ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              doc.fileName ?? doc.displayType,
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (doc.uploadedAt != null)
            Text(
              _formatDate(doc.uploadedAt!),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

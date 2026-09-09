import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/document_provider.dart';

class MyDocumentPage extends ConsumerStatefulWidget {
  const MyDocumentPage({super.key});

  @override
  ConsumerState<MyDocumentPage> createState() => _MyDocumentPageState();
}

class _MyDocumentPageState extends ConsumerState<MyDocumentPage> {
  final _picker = ImagePicker();
  bool _uploadingKtp = false;
  bool _uploadingKk = false;

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(meDocumentsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dokumen Saya'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meDocumentsProvider),
        child: docsAsync.when(
          data: (docs) {
            if (docs == null) return _buildNoResident();
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResidentCard(docs),
                  const SizedBox(height: 20),
                  _buildDocumentSection(
                    title: 'KTP',
                    icon: Icons.badge_outlined,
                    file: docs.ktp,
                    uploading: _uploadingKtp,
                    onUpload: () => _uploadKtp(),
                    onView: docs.ktp != null
                        ? () => _viewFile(
                            'KTP',
                            () => ref
                                .read(meDocumentDataSourceProvider)
                                .downloadKtp(),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentSection(
                    title: 'Kartu Keluarga (KK)',
                    icon: Icons.family_restroom_outlined,
                    file: docs.kk,
                    uploading: _uploadingKk,
                    onUpload: () => _uploadKk(),
                    onView: docs.kk != null
                        ? () => _viewFile(
                            'KK',
                            () => ref
                                .read(meDocumentDataSourceProvider)
                                .downloadKk(),
                          )
                        : null,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(e.toString()),
        ),
      ),
    );
  }

  Widget _buildResidentCard(dynamic docs) {
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docs.resident.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIK: ${docs.resident.nik}',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required IconData icon,
    required dynamic file,
    required bool uploading,
    required VoidCallback onUpload,
    VoidCallback? onView,
  }) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (file != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          file.fileSizeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onView != null)
                    IconButton(
                      icon: const Icon(
                        Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: onView,
                      tooltip: 'Lihat dokumen',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: uploading ? null : onUpload,
              icon: uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(file != null ? Icons.refresh : Icons.upload),
              label: Text(file != null ? 'Ganti Dokumen' : 'Upload Dokumen'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadKtp() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (xfile == null) return;
    setState(() => _uploadingKtp = true);
    try {
      await ref.read(meDocumentDataSourceProvider).uploadKtp(File(xfile.path));
      ref.invalidate(meDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KTP berhasil diupload'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload KTP gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingKtp = false);
    }
  }

  Future<void> _uploadKk() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (xfile == null) return;
    setState(() => _uploadingKk = true);
    try {
      await ref.read(meDocumentDataSourceProvider).uploadKk(File(xfile.path));
      ref.invalidate(meDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KK berhasil diupload'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload KK gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingKk = false);
    }
  }

  Future<void> _viewFile(
    String label,
    Future<List<int>> Function() fetch,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Mengunduh $label...')));
    try {
      final bytes = await fetch();
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            '$label berhasil diunduh (${(bytes.length / 1024).toStringAsFixed(1)} KB)',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildNoResident() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: AppColors.grey),
            SizedBox(height: 16),
            Text(
              'Anda belum terdaftar sebagai warga',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hubungi RT untuk didaftarkan',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gagal memuat data',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

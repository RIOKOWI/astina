import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/activity_model.dart';
import '../../providers/activity_provider.dart';

class ActivityDetailPage extends ConsumerStatefulWidget {
  final int activityId;

  const ActivityDetailPage({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends ConsumerState<ActivityDetailPage> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(activityDetailProvider(widget.activityId));
    final role = ref.watch(currentUserRoleProvider);
    final isRT = role == UserRole.rt;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          if (isRT)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.push('/activities/${widget.activityId}/edit'),
            ),
          if (isRT)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: detailAsync.when(
        data: (activity) {
          final isRead = activity.isRead ?? false;
          if (!isRead) {
            Future.microtask(() => _markAsRead(activity.id));
          }
          return _buildContent(context, activity, isRT, isRead);
        },
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

  Future<void> _markAsRead(int id) async {
    try {
      await ref.read(activityDataSourceProvider).markAsRead(id);
    } catch (_) {}
  }

  Widget _buildContent(BuildContext context, Activity activity, bool isRT, bool isRead) {
    final statusColor = switch (activity.status) {
      'published' => AppColors.success,
      'draft' => AppColors.warning,
      'cancelled' => AppColors.error,
      'completed' => AppColors.primary,
      _ => AppColors.grey,
    };

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(activityDetailProvider(widget.activityId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
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
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  if (activity.creator != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Oleh: ${activity.creator!.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info card
            Container(
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
                  if (activity.description != null) ...[
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (activity.location != null) ...[
                    _infoRow(Icons.location_on, 'Lokasi', activity.location!),
                    const SizedBox(height: 8),
                  ],
                  if (activity.startAt != null) ...[
                    _infoRow(
                      Icons.schedule,
                      'Waktu',
                      '${_formatDateTime(activity.startAt!)}${activity.endAt != null ? ' - ${_formatTime(activity.endAt!)}' : ''}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _infoRow(
                    Icons.calendar_today,
                    'Dibuat',
                    _formatDateTime(activity.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Attachments
            Row(
              children: [
                const Text(
                  'Lampiran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const Spacer(),
                if (isRT)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                    onPressed: _isUploading ? null : () => _uploadAttachment(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (activity.attachments == null || activity.attachments!.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.dark.withValues(alpha: 0.06),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada lampiran',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              )
            else
              ...activity.attachments!.map(
                (a) => _buildAttachmentCard(a, isRT),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(ActivityAttachment a, bool isRT) {
    final isPdf = a.mimeType == 'application/pdf';
    return GestureDetector(
      onTap: () => context.push(
        '/activities/${widget.activityId}/attachments/${a.id}',
        extra: a,
      ),
      child: Container(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPdf
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.image,
                color: isPdf ? Colors.red : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.fileName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    a.fileSizeLabel,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            if (isRT)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => _confirmDeleteAttachment(a),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() => _isUploading = true);
    try {
      await ref
          .read(activityDataSourceProvider)
          .uploadAttachment(widget.activityId, File(path));
      ref.invalidate(activityDetailProvider(widget.activityId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lampiran berhasil diupload'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _confirmDeleteAttachment(ActivityAttachment a) {
    final pageCtx = context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lampiran'),
        content: Text('Hapus ${a.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(activityDataSourceProvider)
                    .deleteAttachment(widget.activityId, a.id);
                ref.invalidate(activityDetailProvider(widget.activityId));
              } catch (e) {
                if (pageCtx.mounted) {
                  ScaffoldMessenger.of(pageCtx).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext dialogCtx) {
    final pageCtx = context;
    showDialog(
      context: dialogCtx,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Aktivitas'),
        content: const Text('Yakin ingin menghapus aktivitas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(activityDataSourceProvider)
                    .deleteActivity(widget.activityId);
                if (pageCtx.mounted) {
                  pageCtx.go('/activities');
                }
              } catch (e) {
                if (pageCtx.mounted) {
                  ScaffoldMessenger.of(pageCtx).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

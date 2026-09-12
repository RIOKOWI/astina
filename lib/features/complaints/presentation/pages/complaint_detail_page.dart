import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import 'complaint_attachment_viewer_page.dart';

class ComplaintDetailPage extends ConsumerStatefulWidget {
  final int complaintId;

  const ComplaintDetailPage({super.key, required this.complaintId});

  @override
  ConsumerState<ComplaintDetailPage> createState() =>
      _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends ConsumerState<ComplaintDetailPage> {
  final _picker = ImagePicker();
  final _commentController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(complaintDetailProvider(widget.complaintId));
    final role = ref.watch(currentUserRoleProvider);
    final isRT = role == UserRole.rt;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Pengaduan'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: detailAsync.when(
        data: (complaint) => _buildContent(complaint, isRT),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              friendlyErrorMessage(e),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Complaint complaint, bool isRT) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(complaintDetailProvider(widget.complaintId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(complaint),
                  const SizedBox(height: 16),
                  _buildInfoCard(complaint),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(complaint),
                  const SizedBox(height: 16),
                  if (complaint.rejectionReason != null)
                    _buildRejectionCard(complaint),
                  if (isRT) ...[
                    const SizedBox(height: 16),
                    _buildStatusActions(complaint),
                  ],
                  const SizedBox(height: 16),
                  _buildCommentsSection(complaint),
                  const SizedBox(height: 16),
                  _buildAttachmentsSection(complaint, isRT),
                ],
              ),
            ),
          ),
        ),
        _buildCommentInput(complaint),
      ],
    );
  }

  Widget _buildHeader(Complaint c) {
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
                  color: _statusColor(c.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(c.status),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.categoryLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.referenceNo,
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            c.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                c.resident!.fullName,
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Complaint c) {
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
          _infoRow('Diajukan', _formatDateTime(c.submittedAt)),
          if (c.reviewedAt != null) ...[
            const SizedBox(height: 8),
            _infoRow('Ditinjau', _formatDateTime(c.reviewedAt!)),
          ],
          if (c.resolvedAt != null) ...[
            const SizedBox(height: 8),
            _infoRow('Diselesaikan', _formatDateTime(c.resolvedAt!)),
          ],
          if (c.closedAt != null) ...[
            const SizedBox(height: 8),
            _infoRow('Ditutup', _formatDateTime(c.closedAt!)),
          ],
          if (c.assignedTo != null) ...[
            const SizedBox(height: 8),
            _infoRow('Ditangani oleh', c.assignedTo!.name),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Complaint c) {
    if (c.description == null || c.description!.isEmpty) {
      return const SizedBox.shrink();
    }
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
            'Deskripsi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.description!,
            style: const TextStyle(fontSize: 14, color: AppColors.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard(Complaint c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.block, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Alasan Penolakan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.rejectionReason!,
            style: const TextStyle(fontSize: 14, color: AppColors.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(Complaint c) {
    final transitions = _getNextStatuses(c.status);
    if (transitions.isEmpty) return const SizedBox.shrink();

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
            'Ubah Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: transitions.entries.map((e) {
              return ElevatedButton(
                onPressed: () => _showStatusDialog(c, e.key, e.value),
                style: ElevatedButton.styleFrom(
                  backgroundColor: e.key == 'rejected'
                      ? AppColors.error
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  e.value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getNextStatuses(String current) {
    switch (current) {
      case 'submitted':
        return {'reviewed': 'Tinjau', 'rejected': 'Tolak'};
      case 'reviewed':
        return {'in_progress': 'Mulai Proses', 'rejected': 'Tolak'};
      case 'in_progress':
        return {'resolved': 'Selesaikan'};
      case 'resolved':
        return {'closed': 'Tutup'};
      default:
        return {};
    }
  }

  void _showStatusDialog(Complaint c, String newStatus, String label) {
    if (newStatus == 'rejected') {
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tolak Pengaduan'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Alasan penolakan',
              hintText: 'Masukkan alasan...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                await _changeStatus(
                  c.id,
                  newStatus,
                  reasonController.text.trim(),
                );
              },
              child: const Text('Tolak'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Ubah ke "$label"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _changeStatus(c.id, newStatus, null);
              },
              child: const Text('Ya'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _changeStatus(int id, String status, String? reason) async {
    try {
      await ref
          .read(complaintDataSourceProvider)
          .updateStatus(id, status: status, rejectionReason: reason);
      ref.invalidate(complaintDetailProvider(id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diubah'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildCommentsSection(Complaint c) {
    final comments = c.comments ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komentar (${comments.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Belum ada komentar',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
          )
        else
          ...comments.map((comment) => _CommentTile(comment: comment)),
      ],
    );
  }

  Widget _buildAttachmentsSection(Complaint c, bool isRT) {
    final attachments = c.attachments ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lampiran (${attachments.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const Spacer(),
            _isUploading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                    onPressed: () => _uploadAttachment(),
                  ),
          ],
        ),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Belum ada lampiran',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
          )
        else
          ...attachments.map(
            (a) => _AttachmentTile(
              a: a,
              isRT: isRT,
              complaintId: c.id,
              onDelete: () => _deleteAttachment(c.id, a.id),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentInput(Complaint c) {
    if (c.status == 'closed' || c.status == 'rejected') {
      return const SizedBox.shrink();
    }
    final inputState = ref.watch(commentInputProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Tulis komentar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: inputState.isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppColors.primary),
              onPressed: inputState.isSubmitting
                  ? null
                  : () => _submitComment(c.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment(int complaintId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final result = await ref
        .read(commentInputProvider.notifier)
        .submit(complaintId, text);
    if (result != null && mounted) {
      _commentController.clear();
    }
  }

  Future<void> _uploadAttachment() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (xfile == null) return;
    setState(() => _isUploading = true);
    try {
      await ref
          .read(complaintDataSourceProvider)
          .uploadAttachment(widget.complaintId, File(xfile.path));
      ref.invalidate(complaintDetailProvider(widget.complaintId));
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

  Future<void> _deleteAttachment(int complaintId, int attachmentId) async {
    try {
      await ref
          .read(complaintDataSourceProvider)
          .deleteAttachment(complaintId, attachmentId);
      ref.invalidate(complaintDetailProvider(complaintId));
    } catch (_) {}
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'submitted':
        return AppColors.primary;
      case 'reviewed':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.grey;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.schedule, size: 16, color: AppColors.primary),
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final ComplaintComment comment;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: comment.user.isRT
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.dark.withValues(alpha: 0.1),
                child: Text(
                  comment.user.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: comment.user.isRT
                        ? AppColors.primary
                        : AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.user.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                        if (comment.user.isRT) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'RT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatTime(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.comment,
            style: const TextStyle(fontSize: 13, color: AppColors.dark),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
    if (diff.inDays < 1) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.a,
    required this.isRT,
    required this.complaintId,
    required this.onDelete,
  });

  final ComplaintAttachment a;
  final bool isRT;
  final int complaintId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPdf = a.mimeType == 'application/pdf';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComplaintAttachmentViewerPage(attachment: a),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
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
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Hapus Lampiran'),
                          content: Text('Hapus ${a.fileName}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              onPressed: () {
                                Navigator.of(dialogCtx).pop();
                                onDelete();
                              },
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

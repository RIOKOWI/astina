import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/payment_model.dart';
import '../../providers/finance_provider.dart';

class PaymentDetailPage extends ConsumerStatefulWidget {
  const PaymentDetailPage({super.key, required this.paymentId});

  final int paymentId;

  @override
  ConsumerState<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends ConsumerState<PaymentDetailPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(paymentDetailProvider(widget.paymentId));
    final role = ref.watch(currentUserRoleProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: paymentAsync.when(
        data: (payment) => _buildContent(payment, role),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(error.toString()),
      ),
    );
  }

  Widget _buildContent(PaymentModel payment, UserRole role) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paymentDetailProvider(widget.paymentId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _PaymentHeader(payment: payment),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Informasi Pembayaran',
            children: [
              _InfoRow(
                label: 'Iuran',
                value: payment.dueBill?.due?.name ?? 'Iuran',
              ),
              _InfoRow(
                label: 'Warga',
                value:
                    payment.resident?.fullName ??
                    'Warga #${payment.residentId}',
              ),
              _InfoRow(label: 'Metode', value: _methodLabel(payment.method)),
              _InfoRow(label: 'Dibayar', value: _formatDate(payment.paidAt)),
              if (payment.dueBill != null)
                _InfoRow(label: 'Jatuh tempo', value: payment.dueBill!.dueDate),
              if (payment.approvedAt != null)
                _InfoRow(
                  label: 'Disetujui',
                  value: _formatDate(payment.approvedAt),
                ),
              if (payment.approver != null)
                _InfoRow(label: 'Oleh', value: payment.approver!.name),
              if (payment.rejectionReason != null)
                _InfoRow(
                  label: 'Alasan ditolak',
                  value: payment.rejectionReason!,
                  valueColor: AppColors.error,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Bukti Pembayaran',
            children: payment.proofs.isEmpty
                ? const [
                    Text(
                      'Belum ada bukti pembayaran',
                      style: TextStyle(fontSize: 13, color: AppColors.grey),
                    ),
                  ]
                : [
                    for (final proof in payment.proofs)
                      _ProofTile(proof: proof, onOpen: () => _openProof(proof)),
                  ],
          ),
          if (role == UserRole.warga && payment.isPending) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _uploadProof,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Bukti'),
            ),
          ],
          if (role == UserRole.bendahara && payment.isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _showRejectDialog,
                    icon: const Icon(Icons.close),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _approve,
                    icon: const Icon(Icons.check),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_isProcessing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat pembayaran',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(paymentDetailProvider(widget.paymentId)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  void _openProof(PaymentProof proof) {
    context.push(
      '/_document_viewer',
      extra: {
        'title': proof.fileName,
        'fileName': proof.fileName,
        'fetchBytes': () => ref
            .read(financeRemoteDataSourceProvider)
            .downloadPaymentProof(proof.url),
      },
    );
  }

  Future<void> _uploadProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
    );
    final file = result?.files.single;
    final path = file?.path;
    if (file == null || path == null) return;

    const maxSize = 5 * 1024 * 1024;
    final size = file.size > 0 ? file.size : await File(path).length();
    if (!mounted) return;
    if (size > maxSize) {
      _showMessage('Ukuran file maksimal 5 MB', isError: true);
      return;
    }

    await _runAction(() async {
      await ref
          .read(financeRemoteDataSourceProvider)
          .uploadPaymentProof(widget.paymentId, path);
      ref.invalidate(paymentDetailProvider(widget.paymentId));
      ref.read(myPaymentsProvider.notifier).load();
      _showMessage('Bukti pembayaran berhasil diupload');
    });
  }

  Future<void> _approve() async {
    await _runAction(() async {
      await ref
          .read(financeRemoteDataSourceProvider)
          .approvePayment(widget.paymentId);
      ref
          .read(pendingPaymentsProvider.notifier)
          .removePayment(widget.paymentId);
      ref.invalidate(paymentDetailProvider(widget.paymentId));
      ref.invalidate(financeSummaryProvider(null));
      _showMessage('Pembayaran disetujui');
    });
  }

  Future<void> _showRejectDialog() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Pembayaran'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan Penolakan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    await _runAction(() async {
      await ref
          .read(financeRemoteDataSourceProvider)
          .rejectPayment(widget.paymentId, reason);
      ref
          .read(pendingPaymentsProvider.notifier)
          .removePayment(widget.paymentId);
      ref.invalidate(paymentDetailProvider(widget.paymentId));
      _showMessage('Pembayaran ditolak');
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } catch (error) {
      _showMessage('Gagal: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(payment.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payment_outlined, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCurrency(payment.amount),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel(payment.status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '#${payment.id}',
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.proof, required this.onOpen});

  final PaymentProof proof;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isPdf = proof.mimeType == 'application/pdf';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
        color: isPdf ? AppColors.error : AppColors.primary,
      ),
      title: Text(
        proof.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        proof.fileSize == null
            ? proof.mimeType
            : _formatFileSize(proof.fileSize!),
        style: const TextStyle(fontSize: 11, color: AppColors.grey),
      ),
      trailing: IconButton(
        onPressed: onOpen,
        icon: const Icon(Icons.visibility_outlined),
        tooltip: 'Lihat bukti',
      ),
      onTap: onOpen,
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'approved' || 'paid' => AppColors.success,
    'rejected' => AppColors.error,
    'pending' => Colors.orange,
    _ => AppColors.grey,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'approved' || 'paid' => 'Lunas',
    'rejected' => 'Ditolak',
    'pending' => 'Menunggu persetujuan',
    _ => status,
  };
}

String _methodLabel(String method) {
  return switch (method) {
    'transfer' => 'Transfer',
    'cash' => 'Tunai',
    'qris' => 'QRIS',
    'ewallet' => 'E-Wallet',
    _ => method,
  };
}

String _formatCurrency(int amount) {
  final value = amount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $value';
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} $hour:$minute';
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

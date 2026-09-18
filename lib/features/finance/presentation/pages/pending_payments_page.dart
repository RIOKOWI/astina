import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../data/models/payment_model.dart';
import '../../providers/finance_provider.dart';

class PendingPaymentsPage extends ConsumerStatefulWidget {
  const PendingPaymentsPage({super.key});

  @override
  ConsumerState<PendingPaymentsPage> createState() =>
      _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends ConsumerState<PendingPaymentsPage> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _load() => ref.read(pendingPaymentsProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingPaymentsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Approval Pembayaran'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: state.error != null
            ? _buildError(state.error!)
            : state.payments.isEmpty && !state.isLoading
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.payments.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.payments.length) {
                    if (state.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    ref.read(pendingPaymentsProvider.notifier).loadMore();
                    return const SizedBox.shrink();
                  }
                  return _PaymentCard(
                    payment: state.payments[index],
                    isProcessing: _isProcessing,
                    onOpen: () async {
                      await context.push(
                        '/finance/payments/${state.payments[index].id}',
                      );
                      if (mounted) _load();
                    },
                    onApprove: () => _approve(state.payments[index].id),
                    onReject: () => _showRejectDialog(state.payments[index].id),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  friendlyErrorMessage(msg),
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Tidak ada pembayaran pending',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _approve(int paymentId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(financeRemoteDataSourceProvider).approvePayment(paymentId);
      ref.read(pendingPaymentsProvider.notifier).removePayment(paymentId);
      ref.invalidate(financeSummaryProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran disetujui'),
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
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog(int paymentId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Pembayaran'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan Penolakan',
            hintText: 'Masukkan alasan penolakan...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _reject(paymentId, reasonController.text.trim());
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(int paymentId, String reason) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(financeRemoteDataSourceProvider)
          .rejectPayment(paymentId, reason);
      ref.read(pendingPaymentsProvider.notifier).removePayment(paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran ditolak'),
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
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.isProcessing,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
  });

  final PaymentModel payment;
  final bool isProcessing;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payment,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.resident?.fullName ?? 'Warga',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      payment.dueBill?.due?.name ?? 'Iuran',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(payment.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Lihat detail',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(Icons.calendar_today, _formatDate(payment.paidAt)),
              _infoChip(Icons.payment, _methodLabel(payment.method)),
              if (payment.proofs.isNotEmpty)
                _infoChip(Icons.attachment, '${payment.proofs.length} bukti'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Setuju'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'transfer':
        return 'Transfer';
      case 'cash':
        return 'Tunai';
      case 'qris':
        return 'QRIS';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return method;
    }
  }
}

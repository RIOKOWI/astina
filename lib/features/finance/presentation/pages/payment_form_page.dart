import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/datasources/finance_remote_data_source.dart';
import '../../providers/finance_provider.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  final DueBillModel bill;

  const PaymentFormPage({super.key, required this.bill});

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  String _method = 'transfer';
  String? _proofPath;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Bayar Tagihan'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bill.due?.name ?? 'Iuran',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jatuh tempo: ${widget.bill.dueDate}',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(widget.bill.amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Metode Pembayaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _methodCard(
                  'transfer',
                  'Transfer',
                  Icons.account_balance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _methodCard('cash', 'Tunai', Icons.payments)),
              const SizedBox(width: 12),
              Expanded(child: _methodCard('qris', 'QRIS', Icons.qr_code)),
            ],
          ),
          const SizedBox(height: 24),
          if (_method == 'transfer' || _method == 'qris') ...[
            const Text(
              'Bukti Pembayaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.dark.withValues(alpha: 0.1),
                  ),
                ),
                child: _proofPath == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: AppColors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Klik untuk upload bukti',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(_proofPath!), fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () =>
                                    setState(() => _proofPath = null),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload bukti transfer (jpg, png, pdf, maks 5MB)',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Kirim Pembayaran',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _methodCard(String value, String label, IconData icon) {
    final isSelected = _method == value;
    final color = AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.dark.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => _proofPath = image.path);
    }
  }

  Future<void> _submit() async {
    if (_method != 'cash' && _proofPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload bukti pembayaran'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      final payment = await ds.createPayment(
        dueBillId: widget.bill.id,
        amount: widget.bill.amount,
        method: _method,
      );

      if (_proofPath != null) {
        await ds.uploadPaymentProof(payment.id, _proofPath!);
      }

      ref.read(myDueBillsProvider.notifier).markAsPaid(widget.bill.id);
      ref.read(myPaymentsProvider.notifier).addPayment(payment);
      if (mounted) {
        context.go('/finance');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pembayaran berhasil dikirim. Menunggu persetujuan bendahara.',
            ),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatCurrency(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }
}

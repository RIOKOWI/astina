import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  String? _proofName;
  int? _createdPaymentId;
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
          const Text(
            'Bukti Pembayaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickProof,
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
                          Icons.upload_file_outlined,
                          size: 40,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pilih bukti pembayaran',
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ],
                    )
                  : _isPdf(_proofName)
                  ? Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                ),
                                child: Text(
                                  _proofName ?? 'Bukti pembayaran.pdf',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _removeProofButton(),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_proofPath!), fit: BoxFit.cover),
                          _removeProofButton(),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Format JPG, JPEG, PNG, atau PDF. Maksimal 5 MB.',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
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
                : Text(
                    _createdPaymentId == null
                        ? 'Kirim Pembayaran'
                        : 'Coba Upload Lagi',
                    style: const TextStyle(color: Colors.white),
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
      onTap: _createdPaymentId == null
          ? () => setState(() => _method = value)
          : null,
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

  Widget _removeProofButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: IconButton(
        onPressed: () => setState(() {
          _proofPath = null;
          _proofName = null;
        }),
        icon: const Icon(Icons.close, color: Colors.white),
        tooltip: 'Hapus bukti',
        style: IconButton.styleFrom(backgroundColor: Colors.black54),
      ),
    );
  }

  bool _isPdf(String? fileName) {
    return fileName?.toLowerCase().endsWith('.pdf') ?? false;
  }

  Future<void> _pickProof() async {
    final source = await showModalBottomSheet<_ProofSource>(
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
              onTap: () => Navigator.pop(ctx, _ProofSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, _ProofSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Pilih File'),
              onTap: () => Navigator.pop(ctx, _ProofSource.file),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    String? path;
    String? name;
    int? size;
    if (source == _ProofSource.file) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );
      final file = result?.files.single;
      path = file?.path;
      name = file?.name;
      size = file?.size;
    } else {
      final image = await ImagePicker().pickImage(
        source: source == _ProofSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 80,
      );
      path = image?.path;
      name = image?.name;
    }

    if (path == null || name == null || !mounted) return;
    size ??= await File(path).length();
    if (!mounted) return;
    if (size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran file maksimal 5 MB'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _proofPath = path;
      _proofName = name;
    });
  }

  Future<void> _submit() async {
    if (_proofPath == null) {
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
      if (_createdPaymentId == null) {
        final payment = await ds.createPayment(
          dueBillId: widget.bill.id,
          amount: widget.bill.amount,
          method: _method,
        );
        if (mounted) {
          setState(() => _createdPaymentId = payment.id);
        } else {
          _createdPaymentId = payment.id;
        }
      }
      await ds.uploadPaymentProof(_createdPaymentId!, _proofPath!);

      ref.read(myDueBillsProvider.notifier).markAsPaid(widget.bill.id);
      ref.invalidate(myPaymentsProvider);
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

enum _ProofSource { camera, gallery, file }

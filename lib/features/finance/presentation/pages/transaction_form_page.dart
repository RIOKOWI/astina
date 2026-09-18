import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/finance_provider.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key});

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'expense';
  DateTime _transactionAt = DateTime.now();
  bool _isSubmitting = false;

  final _commonCategories = {
    'income': ['Iuran', 'Donasi', 'Lainnya'],
    'expense': ['Operasional', 'Perbaikan', 'Kebersihan', 'Lainnya'],
  };

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Catat Transaksi'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tipe Transaksi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _typeCard('expense', 'Pengeluaran', AppColors.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _typeCard('income', 'Pemasukan', AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah (Rp)',
                hintText: 'Contoh: 100000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                final amount = int.tryParse(v);
                if (amount == null) return 'Masukkan angka yang valid';
                if (amount < 100) return 'Jumlah minimal Rp 100';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Kategori',
                hintText: 'Contoh: Operasional',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Kategori wajib diisi' : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonCategories[_type]!.map((cat) {
                return ActionChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _categoryController.text = cat,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Keterangan (opsional)',
                hintText: 'Deskripsi transaksi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                ),
              ),
              title: const Text(
                'Tanggal Transaksi',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                '${_transactionAt.day}/${_transactionAt.month}/${_transactionAt.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _transactionAt,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _transactionAt = date);
                }
              },
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
                  : const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(String type, String label, Color color) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
          _categoryController.clear();
        });
      },
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
            Icon(
              type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
              color: isSelected ? color : AppColors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      await ds.createTransaction(
        type: _type,
        amount: int.parse(_amountController.text.trim()),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        transactionAt: _transactionAt.toIso8601String(),
      );
      ref.invalidate(transactionListProvider);
      ref.invalidate(financeSummaryProvider(null));
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dicatat'),
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
}

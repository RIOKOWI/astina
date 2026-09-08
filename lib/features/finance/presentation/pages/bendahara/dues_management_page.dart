import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../providers/bendahara_provider.dart';
import '../../../data/models/bendahara/due_model.dart';

class DuesManagementPage extends ConsumerWidget {
  const DuesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(duesProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Kelola Iuran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDueForm(context, ref),
          ),
        ],
      ),
      body: duesAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dues) {
          if (dues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppColors.grey),
                  const SizedBox(height: 16),
                  Text('Belum ada iuran', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showDueForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Iuran'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(duesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dues.length,
              itemBuilder: (context, index) {
                final due = dues[index];
                return _DueCard(
                  due: due,
                  onEdit: () => _showDueForm(context, ref, due: due),
                  onDelete: () => _confirmDelete(context, ref, due),
                  onToggle: () => _toggleActive(ref, due),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showDueForm(BuildContext context, WidgetRef ref, {DueModel? due}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DueFormSheet(due: due),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DueModel due) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Iuran?'),
        content: Text('Yakin ingin menghapus "${due.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(bendaharaNotifierProvider.notifier)
                  .deleteDue(due.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _toggleActive(WidgetRef ref, DueModel due) {
    ref
        .read(bendaharaNotifierProvider.notifier)
        .updateDue(
          due.id,
          name: due.name,
          amount: due.amount,
          description: due.description,
          frequency: due.frequency,
          isActive: !due.isActive,
        );
  }
}

class _DueCard extends StatelessWidget {
  final DueModel due;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _DueCard({
    required this.due,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: due.isActive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              due.isActive ? 'AKTIF' : 'NONAKTIF',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: due.isActive
                                    ? AppColors.success
                                    : AppColors.grey,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              due.frequencyLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        due.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (due.description != null &&
                          due.description!.isNotEmpty)
                        Text(
                          due.description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  due.formattedAmount,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      due.isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(due.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: due.isActive
                          ? AppColors.warning
                          : AppColors.success,
                      side: BorderSide(
                        color: due.isActive
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  color: AppColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onDelete,
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DueFormSheet extends ConsumerStatefulWidget {
  final DueModel? due;

  const _DueFormSheet({this.due});

  @override
  ConsumerState<_DueFormSheet> createState() => _DueFormSheetState();
}

class _DueFormSheetState extends ConsumerState<_DueFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _frequency = 'monthly';

  @override
  void initState() {
    super.initState();
    if (widget.due != null) {
      _nameController.text = widget.due!.name;
      _amountController.text = widget.due!.amount.toString();
      _descController.text = widget.due!.description ?? '';
      _frequency = widget.due!.frequency ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(bendaharaNotifierProvider).valueOrNull?.isSubmitting ?? false;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.due != null ? 'Edit Iuran' : 'Tambah Iuran',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Iuran',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(v) == null) return 'Harus angka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Frekuensi',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _freqChip('monthly', 'Bulanan'),
                  _freqChip('quarterly', 'Per 3 Bulan'),
                  _freqChip('yearly', 'Tahunan'),
                  _freqChip('one_time', 'Sekali'),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.due != null ? 'Simpan' : 'Tambah'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _freqChip(String value, String label) {
    final isSelected = _frequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) setState(() => _frequency = value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.grey,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.parse(_amountController.text);
    final desc = _descController.text.trim();

    Navigator.pop(context);

    if (widget.due != null) {
      await ref
          .read(bendaharaNotifierProvider.notifier)
          .updateDue(
            widget.due!.id,
            name: _nameController.text.trim(),
            amount: amount,
            description: desc.isEmpty ? null : desc,
            frequency: _frequency,
          );
    } else {
      await ref
          .read(bendaharaNotifierProvider.notifier)
          .createDue(
            name: _nameController.text.trim(),
            amount: amount,
            description: desc.isEmpty ? null : desc,
            frequency: _frequency,
          );
    }
  }
}

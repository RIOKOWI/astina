import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/due_model.dart';
import '../../providers/finance_provider.dart';

class DuesPage extends ConsumerStatefulWidget {
  const DuesPage({super.key});

  @override
  ConsumerState<DuesPage> createState() => _DuesPageState();
}

class _DuesPageState extends ConsumerState<DuesPage> {
  bool _includeInactive = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _load() => ref
      .read(duesListProvider.notifier)
      .load(includeInactive: _includeInactive);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duesListProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Kelola Iuran'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Generate Tagihan Bulanan',
            onPressed: () => _showGenerateDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Aktif'),
                    selected: !_includeInactive,
                    onSelected: (_) {
                      setState(() => _includeInactive = false);
                      _load();
                    },
                  ),
                  FilterChip(
                    label: const Text('Semua'),
                    selected: _includeInactive,
                    onSelected: (_) {
                      setState(() => _includeInactive = true);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: state.error != null
                  ? _buildError(state.error!)
                  : state.dues.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.dues.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.dues.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          ref
                              .read(duesListProvider.notifier)
                              .loadMore(includeInactive: _includeInactive);
                          return const SizedBox.shrink();
                        }
                        return _DueCard(
                          due: state.dues[index],
                          onTap: () => context.push(
                            '/finance/dues/${state.dues[index].id}',
                          ),
                          onEdit: () => _showFormDialog(state.dues[index]),
                          onDelete: () => _confirmDelete(state.dues[index].id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(null),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Belum ada iuran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat iuran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
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

  void _showFormDialog(DueModel? existingDue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _DueFormSheet(existingDue: existingDue, onSaved: _load),
    );
  }

  void _showGenerateDialog() {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate Tagihan Bulanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                decoration: const InputDecoration(labelText: 'Tahun'),
                items: List.generate(5, (i) => now.year - 2 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedYear = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                decoration: const InputDecoration(labelText: 'Bulan'),
                items: List.generate(12, (i) => i + 1)
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(_monthName(m)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedMonth = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final created = await ref
                      .read(financeRemoteDataSourceProvider)
                      .generateBills(year: selectedYear, month: selectedMonth);
                  if (mounted) {
                    _load();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$created tagihan ${_monthName(selectedMonth)} $selectedYear berhasil dibuat',
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
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int dueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Iuran'),
        content: const Text(
          'Iuran akan dinonaktifkan. Tagihan yang sudah ada tetap berlaku.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(financeRemoteDataSourceProvider).deleteDue(dueId);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Iuran dinonaktifkan'),
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
  }

  String _monthName(int m) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[m];
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({
    required this.due,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DueModel due;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                          Text(
                            due.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (due.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              due.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
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
                        due.isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: due.isActive
                              ? AppColors.success
                              : AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoChip(_formatCurrency(due.amount)),
                    const SizedBox(width: 8),
                    _infoChip(due.frequencyLabel),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit iuran',
                      color: AppColors.grey,
                      onPressed: () {
                        onEdit();
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Nonaktifkan iuran',
                      color: AppColors.error,
                      onPressed: onDelete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.grey),
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
}

class _DueFormSheet extends ConsumerStatefulWidget {
  const _DueFormSheet({required this.existingDue, required this.onSaved});

  final DueModel? existingDue;
  final VoidCallback onSaved;

  @override
  ConsumerState<_DueFormSheet> createState() => _DueFormSheetState();
}

class _DueFormSheetState extends ConsumerState<_DueFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _frequency = 'monthly';
  bool _isActive = true;
  bool _isSubmitting = false;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get isEditing => widget.existingDue != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final due = widget.existingDue!;
      _nameController.text = due.name;
      _amountController.text = due.amount.toString();
      _descriptionController.text = due.description ?? '';
      _frequency = due.frequency == 'one_time'
          ? 'one-time'
          : due.frequency ?? 'monthly';
      _isActive = due.isActive;
      _startDate = DateTime.tryParse(due.startDate ?? '');
      _endDate = DateTime.tryParse(due.endDate ?? '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Iuran' : 'Tambah Iuran',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Nama Iuran',
                  hintText: 'Contoh: Iuran Bulanan RT 05',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  hintText: 'Contoh: 50000',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                  final amount = int.tryParse(v);
                  if (amount == null) {
                    return 'Masukkan angka yang valid';
                  }
                  if (amount < 100) return 'Jumlah minimal Rp 100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frekuensi',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                  DropdownMenuItem(
                    value: 'quarterly',
                    child: Text('Triwulanan'),
                  ),
                  DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
                  DropdownMenuItem(value: 'one-time', child: Text('Sekali')),
                ],
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Tanggal Mulai',
                      value: _startDate,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateField(
                      label: 'Tanggal Selesai',
                      value: _endDate,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              if (_startDate != null &&
                  _endDate != null &&
                  _endDate!.isBefore(_startDate!)) ...[
                const SizedBox(height: 6),
                const Text(
                  'Tanggal selesai tidak boleh sebelum tanggal mulai',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Iuran Aktif'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                          isEditing ? 'Simpan' : 'Tambah',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  onPressed: () {
                    setState(() {
                      if (label == 'Tanggal Mulai') {
                        _startDate = null;
                      } else {
                        _endDate = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Hapus tanggal',
                ),
        ),
        child: Text(value == null ? 'Opsional' : _formatDate(value)),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? _startDate ?? DateTime.now()
        : _endDate ?? _startDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(financeRemoteDataSourceProvider);
      if (isEditing) {
        await ds.updateDue(
          widget.existingDue!.id,
          name: _nameController.text.trim(),
          amount: int.parse(_amountController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          frequency: _frequency,
          startDate: _startDate == null ? null : _formatDate(_startDate!),
          endDate: _endDate == null ? null : _formatDate(_endDate!),
          isActive: _isActive,
          includeDescription: true,
          includeStartDate: true,
          includeEndDate: true,
        );
      } else {
        await ds.createDue(
          name: _nameController.text.trim(),
          amount: int.parse(_amountController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          frequency: _frequency,
          startDate: _startDate == null ? null : _formatDate(_startDate!),
          endDate: _endDate == null ? null : _formatDate(_endDate!),
          isActive: _isActive,
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
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

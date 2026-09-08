import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/inventory_provider.dart';

class CreateAssetPage extends ConsumerStatefulWidget {
  const CreateAssetPage({super.key});

  @override
  ConsumerState<CreateAssetPage> createState() => _CreateAssetPageState();
}

class _CreateAssetPageState extends ConsumerState<CreateAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '0');
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchaseDateController = TextEditingController();

  String _condition = 'good';
  String _status = 'available';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Tambah Asset'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCard([
                _buildSectionTitle('Informasi Dasar'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Asset *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama harus diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    hintText: 'contoh: Furniture, Elektronik',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Kategori harus diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildSectionTitle('Stok & Satuan'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Awal',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan *',
                          hintText: 'pcs, unit',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib' : null,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildSectionTitle('Informasi Pembelian'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Beli',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purchaseDateController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Pembelian',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      _purchaseDateController.text = date
                          .toIso8601String()
                          .split('T')[0];
                    }
                  },
                ),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildSectionTitle('Kondisi & Status'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: const InputDecoration(labelText: 'Kondisi'),
                  items: const [
                    DropdownMenuItem(value: 'new', child: Text('Baru')),
                    DropdownMenuItem(value: 'good', child: Text('Baik')),
                    DropdownMenuItem(value: 'fair', child: Text('Cukup Baik')),
                    DropdownMenuItem(value: 'poor', child: Text('Rusak')),
                  ],
                  onChanged: (v) => setState(() => _condition = v ?? 'good'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Tersedia'),
                    ),
                    DropdownMenuItem(
                      value: 'in_use',
                      child: Text('Sedang Dipakai'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Perbaikan'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'available'),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Asset',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final price = double.tryParse(
        _priceController.text.replaceAll('.', '').replaceAll(',', ''),
      );
      final qty = int.tryParse(_qtyController.text) ?? 0;

      await ref.read(inventoryNotifierProvider.notifier).createAsset({
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        'quantity': qty,
        'unit': _unitController.text.trim(),
        if (price != null) 'purchase_price': price,
        if (_purchaseDateController.text.isNotEmpty)
          'purchase_date': _purchaseDateController.text,
        'condition': _condition,
        'status': _status,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset berhasil dibuat'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat asset: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

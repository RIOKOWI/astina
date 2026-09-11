import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/inventory_provider.dart';

class AssetFormPage extends ConsumerStatefulWidget {
  final int? assetId;

  const AssetFormPage({super.key, this.assetId});

  @override
  ConsumerState<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends ConsumerState<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  String _condition = 'good';
  String _status = 'available';
  bool _isSubmitting = false;
  bool _isLoading = false;

  bool get isEditing => widget.assetId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      Future.microtask(_loadAsset);
    }
  }

  Future<void> _loadAsset() async {
    setState(() => _isLoading = true);
    try {
      final asset = await ref
          .read(inventoryDataSourceProvider)
          .getAsset(widget.assetId!);
      if (mounted) {
        setState(() {
          _nameController.text = asset.name;
          _categoryController.text = asset.category;
          _descriptionController.text = asset.description ?? '';
          _unitController.text = asset.unit;
          _quantityController.text = asset.quantity.toString();
          _purchasePriceController.text = asset.purchasePrice ?? '';
          _condition = asset.condition ?? 'good';
          _status = asset.status ?? 'available';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Aset' : 'Tambah Aset'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nama Aset',
                    hint: 'Contoh: Kursi Plastik Hitam',
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _categoryController,
                    label: 'Kategori',
                    hint: 'Contoh: Furniture',
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _unitController,
                    label: 'Unit',
                    hint: 'Contoh: pcs, unit, box',
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _quantityController,
                    label: 'Jumlah Stok Awal',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    enabled: !isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _purchasePriceController,
                    label: 'Harga Beli (Rp)',
                    hint: '75000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Deskripsi',
                    hint: 'Deskripsi aset...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Kondisi',
                    value: _condition,
                    items: const [
                      DropdownMenuItem(value: 'new', child: Text('Baru')),
                      DropdownMenuItem(value: 'good', child: Text('Baik')),
                      DropdownMenuItem(value: 'fair', child: Text('Cukup')),
                      DropdownMenuItem(value: 'poor', child: Text('Rusak')),
                    ],
                    onChanged: (v) => setState(() => _condition = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Status',
                    value: _status,
                    items: const [
                      DropdownMenuItem(
                        value: 'available',
                        child: Text('Tersedia'),
                      ),
                      DropdownMenuItem(value: 'in_use', child: Text('Dipakai')),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('Perbaikan'),
                      ),
                      DropdownMenuItem(
                        value: 'retired',
                        child: Text('Nonaktif'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
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
                            isEditing ? 'Simpan Perubahan' : 'Tambah Aset',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: required
              ? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(inventoryDataSourceProvider);
      if (isEditing) {
        await ds.updateAsset(
          widget.assetId!,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          unit: _unitController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          purchasePrice: _purchasePriceController.text.trim().isEmpty
              ? null
              : int.tryParse(_purchasePriceController.text.trim()),
          condition: _condition,
          status: _status,
        );
      } else {
        await ds.createAsset(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          unit: _unitController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
          purchasePrice: _purchasePriceController.text.trim().isEmpty
              ? null
              : int.tryParse(_purchasePriceController.text.trim()),
          condition: _condition,
          status: _status,
        );
      }
      ref.invalidate(inventoryListProvider);
      if (mounted) {
        context.go('/inventory');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Aset berhasil diperbarui'
                  : 'Aset berhasil ditambahkan',
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
}

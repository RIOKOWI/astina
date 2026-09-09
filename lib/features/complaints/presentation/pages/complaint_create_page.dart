import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/complaint_provider.dart';

class ComplaintCreatePage extends ConsumerStatefulWidget {
  const ComplaintCreatePage({super.key});

  @override
  ConsumerState<ComplaintCreatePage> createState() => _ComplaintCreatePageState();
}

class _ComplaintCreatePageState extends ConsumerState<ComplaintCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _category;
  bool _isSubmitting = false;
  String? _errorMsg;

  final _categories = [
    ('facility', 'Fasilitas'),
    ('security', 'Keamanan'),
    ('cleanliness', 'Kebersihan'),
    ('noise', 'Kebisingan'),
    ('dispute', 'Perselisihan'),
    ('other', 'Lainnya'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _errorMsg = 'Kategori wajib dipilih');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      await ref.read(complaintDataSourceProvider).createComplaint(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category!,
      );
      ref.read(complaintsListProvider.notifier).load();
      if (mounted) {
        context.go('/complaints');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaduan berhasil diajukan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Buat Pengaduan'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_errorMsg!, style: const TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 16),
              ],
              _buildCard([
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Judul *'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Kategori *'),
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c.$1,
                      child: Text(c.$2),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Wajib dipilih' : null,
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ajukan Pengaduan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
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
        children: children,
      ),
    );
  }
}

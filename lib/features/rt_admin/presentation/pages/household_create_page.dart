import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/rt_admin_provider.dart';

class HouseholdCreatePage extends ConsumerStatefulWidget {
  const HouseholdCreatePage({super.key});

  @override
  ConsumerState<HouseholdCreatePage> createState() =>
      _HouseholdCreatePageState();
}

class _HouseholdCreatePageState extends ConsumerState<HouseholdCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _noKkController = TextEditingController();
  final _addressController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _headNikController = TextEditingController();

  @override
  void dispose() {
    _noKkController.dispose();
    _addressController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _postalCodeController.dispose();
    _headNikController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'no_kk': _noKkController.text.trim(),
      'address': _addressController.text.trim(),
      'rt': _rtController.text.trim(),
      'rw': _rwController.text.trim(),
    };

    if (_postalCodeController.text.trim().isNotEmpty) {
      data['postal_code'] = _postalCodeController.text.trim();
    }
    if (_headNikController.text.trim().isNotEmpty) {
      data['head_nik'] = _headNikController.text.trim();
    }

    final result = await ref
        .read(rtHouseholdNotifierProvider.notifier)
        .create(data);

    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data keluarga berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final err = ref
          .read(rtHouseholdNotifierProvider)
          .valueOrNull
          ?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Gagal membuat data keluarga'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rtHouseholdNotifierProvider);
    final isSubmitting = state.valueOrNull?.isProcessing ?? false;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Tambah KK'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSection('Informasi KK', [
                _buildTextField(
                  controller: _noKkController,
                  label: 'Nomor KK',
                  hint: '16 digit nomor kartu keluarga',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Nomor KK wajib diisi';
                    if (v.trim().length < 10)
                      return 'Nomor KK minimal 10 digit';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Alamat',
                  hint: 'Contoh: Jl. Mawar No. 12',
                  maxLines: 3,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Alamat wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _rtController,
                        label: 'RT',
                        hint: '005',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'RT wajib diisi';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _rwController,
                        label: 'RW',
                        hint: '016',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'RW wajib diisi';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _postalCodeController,
                  label: 'Kode Pos',
                  hint: 'Contoh: 15111',
                  keyboardType: TextInputType.number,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Kepala Keluarga', [
                _buildTextField(
                  controller: _headNikController,
                  label: 'NIK Kepala Keluarga',
                  hint: 'NIK warga yang menjadi kepala keluarga',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'NIK kepala keluarga wajib diisi';
                    }
                    if (v.trim().length < 10) {
                      return 'NIK minimal 10 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pastikan warga sudah terdaftar di sistem sebelum membuat KK.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

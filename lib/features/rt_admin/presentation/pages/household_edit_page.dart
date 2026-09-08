import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/rt_admin_provider.dart';
import '../../data/models/rt_household_model.dart';

class HouseholdEditPage extends ConsumerStatefulWidget {
  final int householdId;

  const HouseholdEditPage({super.key, required this.householdId});

  @override
  ConsumerState<HouseholdEditPage> createState() => _HouseholdEditPageState();
}

class _HouseholdEditPageState extends ConsumerState<HouseholdEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _noKkController = TextEditingController();
  final _addressController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _postalCodeController = TextEditingController();
  String _status = 'active';
  bool _initialized = false;

  @override
  void dispose() {
    _noKkController.dispose();
    _addressController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _initForm(RtHouseholdModel h) {
    if (_initialized) return;
    _initialized = true;
    _noKkController.text = h.noKk ?? '';
    _addressController.text = h.address ?? '';
    _rtController.text = h.rt ?? '';
    _rwController.text = h.rw ?? '';
    _postalCodeController.text = h.postalCode ?? '';
    _status = h.status;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{};

    if (_noKkController.text.trim().isNotEmpty) {
      data['no_kk'] = _noKkController.text.trim();
    }
    if (_addressController.text.trim().isNotEmpty) {
      data['address'] = _addressController.text.trim();
    }
    if (_rtController.text.trim().isNotEmpty) {
      data['rt'] = _rtController.text.trim();
    }
    if (_rwController.text.trim().isNotEmpty) {
      data['rw'] = _rwController.text.trim();
    }
    if (_postalCodeController.text.trim().isNotEmpty) {
      data['postal_code'] = _postalCodeController.text.trim();
    }
    data['status'] = _status;

    final result = await ref
        .read(rtHouseholdNotifierProvider.notifier)
        .updateHousehold(widget.householdId, data);

    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data keluarga berhasil diperbarui'),
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
          content: Text(err ?? 'Gagal memperbarui data keluarga'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      rtHouseholdDetailProvider(widget.householdId),
    );
    final state = ref.watch(rtHouseholdNotifierProvider);
    final isSubmitting = state.valueOrNull?.isProcessing ?? false;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit KK'),
      ),
      body: detailAsync.when(
        loading: () => Skeletonizer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                5,
                (_) => Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (household) {
          _initForm(household);
          return SingleChildScrollView(
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
                        if (v == null || v.trim().isEmpty) {
                          return 'Nomor KK wajib diisi';
                        }
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
                        if (v == null || v.trim().isEmpty) {
                          return 'Alamat wajib diisi';
                        }
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
                              if (v == null || v.trim().isEmpty) {
                                return 'RT wajib diisi';
                              }
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
                              if (v == null || v.trim().isEmpty) {
                                return 'RW wajib diisi';
                              }
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
                  _buildSection('Status', [
                    Row(
                      children: [
                        _statusOption('active', 'Aktif'),
                        const SizedBox(width: 12),
                        _statusOption('inactive', 'Nonaktif'),
                      ],
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
          );
        },
      ),
    );
  }

  Widget _statusOption(String value, String label) {
    final isSelected = _status == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
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

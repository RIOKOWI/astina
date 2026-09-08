import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/rt_admin_provider.dart';
import '../../data/models/rt_resident_model.dart';

class ResidentEditPage extends ConsumerStatefulWidget {
  final int residentId;

  const ResidentEditPage({super.key, required this.residentId});

  @override
  ConsumerState<ResidentEditPage> createState() => _ResidentEditPageState();
}

class _ResidentEditPageState extends ConsumerState<ResidentEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _occupationController = TextEditingController();
  final _lastEducationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _birthDate;
  String _gender = 'male';
  String _maritalStatus = 'single';
  String _status = 'active';
  bool _initialized = false;

  final _genders = const [
    {'value': 'male', 'label': 'Laki-laki'},
    {'value': 'female', 'label': 'Perempuan'},
  ];

  final _maritalStatuses = const [
    {'value': 'single', 'label': 'Belum Menikah'},
    {'value': 'married', 'label': 'Menikah'},
    {'value': 'divorced', 'label': 'Cerai'},
    {'value': 'widowed', 'label': 'Duda/Janda'},
  ];

  final _statuses = const [
    {'value': 'active', 'label': 'Aktif'},
    {'value': 'inactive', 'label': 'Nonaktif'},
    {'value': 'moved', 'label': 'Pindah'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    _occupationController.dispose();
    _lastEducationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initForm(RtResidentModel r) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = r.fullName;
    _birthPlaceController.text = r.birthPlace ?? '';
    _occupationController.text = r.occupation ?? '';
    _lastEducationController.text = r.lastEducation ?? '';
    _phoneController.text = r.phone ?? '';
    _emailController.text = r.email ?? '';
    _birthDate = r.birthDate;
    _gender = r.gender ?? 'male';
    _maritalStatus = r.maritalStatus ?? 'single';
    _status = r.status;
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{};

    final name = _nameController.text.trim();
    if (name.isNotEmpty) data['full_name'] = name;

    if (_birthPlaceController.text.trim().isNotEmpty) {
      data['birth_place'] = _birthPlaceController.text.trim();
    }
    if (_birthDate != null) {
      data['birth_date'] =
          '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
    }
    data['gender'] = _gender;
    data['marital_status'] = _maritalStatus;
    data['status'] = _status;

    if (_occupationController.text.trim().isNotEmpty) {
      data['occupation'] = _occupationController.text.trim();
    }
    if (_lastEducationController.text.trim().isNotEmpty) {
      data['last_education'] = _lastEducationController.text.trim();
    }
    if (_phoneController.text.trim().isNotEmpty) {
      data['phone'] = _phoneController.text.trim();
    }
    if (_emailController.text.trim().isNotEmpty) {
      data['email'] = _emailController.text.trim();
    }

    final result = await ref
        .read(rtResidentNotifierProvider.notifier)
        .updateResident(widget.residentId, data);

    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data warga berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final err = ref
          .read(rtResidentNotifierProvider)
          .valueOrNull
          ?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Gagal memperbarui data warga'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(rtResidentDetailProvider(widget.residentId));
    final state = ref.watch(rtResidentNotifierProvider);
    final isSubmitting = state.valueOrNull?.isProcessing ?? false;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Warga'),
      ),
      body: detailAsync.when(
        loading: () => Skeletonizer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                6,
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
        data: (resident) {
          _initForm(resident);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSection('Data Diri', [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      hint: 'Nama sesuai KTP',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _birthPlaceController,
                      label: 'Tempat Lahir',
                      hint: 'Contoh: Jakarta',
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      'Tanggal Lahir',
                      _birthDate,
                      _selectBirthDate,
                    ),
                    const SizedBox(height: 16),
                    _buildSegmentedField('Jenis Kelamin', _gender, _genders, (
                      v,
                    ) {
                      setState(() => _gender = v);
                    }),
                    const SizedBox(height: 16),
                    _buildSegmentedField(
                      'Status Perkawinan',
                      _maritalStatus,
                      _maritalStatuses,
                      (v) {
                        setState(() => _maritalStatus = v);
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Status', [
                    _buildSegmentedField('Status Warga', _status, _statuses, (
                      v,
                    ) {
                      setState(() => _status = v);
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Informasi Tambahan', [
                    _buildTextField(
                      controller: _occupationController,
                      label: 'Pekerjaan',
                      hint: 'Contoh: Karyawan Swasta',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _lastEducationController,
                      label: 'Pendidikan Terakhir',
                      hint: 'Contoh: S1',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Nomor HP',
                      hint: '08xxxxxxxxxx',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'email@contoh.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            !v.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    if (resident.hasAccount) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Warga ini memiliki akun. Ubah phone/email via menu Akun Warga.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? '${value.day} ${_months[value.month - 1]} ${value.year}'
                        : 'Pilih tanggal',
                    style: AppTextStyles.body.copyWith(
                      color: value != null ? AppColors.dark : AppColors.grey,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, color: AppColors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedField(
    String label,
    String value,
    List<Map<String, String>> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = value == opt['value'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: opt != options.last ? 8 : 0),
                child: InkWell(
                  onTap: () => onChanged(opt['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        opt['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
}

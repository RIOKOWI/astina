import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../providers/resident_admin_provider.dart';

class ResidentFormPage extends ConsumerStatefulWidget {
  final int? residentId;

  const ResidentFormPage({super.key, this.residentId});

  @override
  ConsumerState<ResidentFormPage> createState() => _ResidentFormPageState();
}

class _ResidentFormPageState extends ConsumerState<ResidentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _occupationController = TextEditingController();
  final _educationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _joinedAtController = TextEditingController();
  String _gender = 'male';
  String _maritalStatus = 'single';
  String _status = 'active';
  DateTime? _birthDate;
  DateTime? _joinedAt;
  bool _isLoading = false;
  bool _isSubmitting = false;

  bool get isEditing => widget.residentId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _isLoading = true;
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    try {
      final ds = ref.read(residentAdminDataSourceProvider);
      final resident = await ds.getResident(widget.residentId!);
      if (mounted) {
        setState(() {
          _nikController.text = resident.nik;
          _nameController.text = resident.fullName;
          _birthPlaceController.text = resident.birthPlace ?? '';
          _occupationController.text = resident.occupation ?? '';
          _educationController.text = resident.lastEducation ?? '';
          _phoneController.text = resident.phone ?? '';
          _emailController.text = resident.email ?? '';
          _joinedAtController.text = resident.joinedAt ?? '';
          _gender = resident.gender ?? 'male';
          _maritalStatus = resident.maritalStatus ?? 'single';
          _status = resident.status;
          if (resident.birthDate != null) {
            try {
              _birthDate = DateTime.parse(resident.birthDate!);
            } catch (_) {}
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _birthPlaceController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _joinedAtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Warga' : 'Tambah Warga'),
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
                  _buildSection('Data Pribadi', [
                    _textField(_nikController, 'NIK', required: true),
                    _textField(_nameController, 'Nama Lengkap', required: true),
                    _textField(_birthPlaceController, 'Tempat Lahir'),
                    _dateField(
                      'Tanggal Lahir',
                      _birthDate,
                      (d) => setState(() => _birthDate = d),
                    ),
                    _dropdown('Jenis Kelamin', _gender, {
                      'male': 'Laki-laki',
                      'female': 'Perempuan',
                    }, (v) => setState(() => _gender = v!)),
                    _dropdown('Agama', _religion, {
                      'islam': 'Islam',
                      'kristen': 'Kristen',
                      'katolik': 'Katolik',
                      'hindu': 'Hindu',
                      'buddha': 'Buddha',
                      'konghucu': 'Konghucu',
                    }, (v) => setState(() => _religion = v)),
                    _dropdown(
                      'Status Pernikahan',
                      _maritalStatus,
                      {
                        'single': 'Belum Menikah',
                        'married': 'Menikah',
                        'divorced': 'Cerai',
                        'widowed': 'Duda/Janda',
                      },
                      (v) => setState(() => _maritalStatus = v!),
                    ),
                    _textField(_occupationController, 'Pekerjaan'),
                    _textField(_educationController, 'Pendidikan Terakhir'),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Kontak', [
                    _textField(_phoneController, 'Telepon'),
                    _textField(_emailController, 'Email'),
                  ]),
                  if (isEditing) ...[
                    const SizedBox(height: 16),
                    _buildSection('Status', [
                      _dropdown('Status Warga', _status, {
                        'active': 'Aktif',
                        'inactive': 'Nonaktif',
                        'moved': 'Pindah',
                      }, (v) => setState(() => _status = v!)),
                    ]),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildSection('Lainnya', [
                      _dateField(
                        'Tanggal Masuk',
                        _joinedAt,
                        (d) => setState(() => _joinedAt = d),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                              isEditing ? 'Simpan' : 'Tambah',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String? _religion;

  Widget _buildSection(String title, List<Widget> children) {
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
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null
            : null,
      ),
    );
  }

  Widget _dropdown(
    String label,
    dynamic value,
    Map<String, String> items,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value?.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    void Function(DateTime?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime(1990),
            firstDate: DateTime(1940),
            lastDate: DateTime.now(),
          );
          onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today, size: 20),
          ),
          child: Text(
            value != null ? '${value.day}/${value.month}/${value.year}' : '-',
            style: TextStyle(
              color: value != null ? AppColors.dark : AppColors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(residentAdminDataSourceProvider);
      final body = <String, dynamic>{};
      if (isEditing) {
        body['nik'] = _nikController.text.trim();
        if (_nameController.text.isNotEmpty)
          body['full_name'] = _nameController.text.trim();
        if (_occupationController.text.isNotEmpty)
          body['occupation'] = _occupationController.text.trim();
        if (_educationController.text.isNotEmpty)
          body['last_education'] = _educationController.text.trim();
        body['gender'] = _gender;
        body['marital_status'] = _maritalStatus;
        if (_religion != null) body['religion'] = _religion;
        body['status'] = _status;
        if (_birthDate != null)
          body['birth_date'] = _birthDate!.toIso8601String().split('T').first;
        if (_birthPlaceController.text.isNotEmpty)
          body['birth_place'] = _birthPlaceController.text.trim();
        await ds.updateResident(widget.residentId!, body);
      } else {
        body['nik'] = _nikController.text.trim();
        body['full_name'] = _nameController.text.trim();
        body['gender'] = _gender;
        body['marital_status'] = _maritalStatus;
        if (_birthPlaceController.text.isNotEmpty)
          body['birth_place'] = _birthPlaceController.text.trim();
        if (_birthDate != null)
          body['birth_date'] = _birthDate!.toIso8601String().split('T').first;
        if (_occupationController.text.isNotEmpty)
          body['occupation'] = _occupationController.text.trim();
        if (_educationController.text.isNotEmpty)
          body['last_education'] = _educationController.text.trim();
        if (_phoneController.text.isNotEmpty)
          body['phone'] = _phoneController.text.trim();
        if (_emailController.text.isNotEmpty)
          body['email'] = _emailController.text.trim();
        if (_joinedAt != null)
          body['joined_at'] = _joinedAt!.toIso8601String().split('T').first;
        if (_religion != null) body['religion'] = _religion;
        await ds.createResident(body);
      }

      ref.invalidate(residentsListProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Data warga berhasil diperbarui'
                  : 'Warga berhasil ditambahkan',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on DioException catch (e) {
      String message = 'Terjadi kesalahan. Silakan coba lagi.';
      if (e.response?.statusCode == 422) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final errors = data['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.containsKey('nik')) {
            final nikErrors = errors['nik'];
            if (nikErrors is List && nikErrors.isNotEmpty) {
              message = 'NIK: ${nikErrors.first}';
            } else if (nikErrors is String) {
              message = 'NIK: $nikErrors';
            }
          }
          if (message == 'Terjadi kesalahan. Silakan coba lagi.' &&
              data.containsKey('message')) {
            message = data['message'].toString();
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Koneksi timeout. Periksa jaringan Anda.';
      } else if (e.response?.statusCode == 401) {
        message = 'Sesi habis. Silakan login ulang.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

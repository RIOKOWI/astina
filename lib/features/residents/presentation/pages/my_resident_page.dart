import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/resident_provider.dart';

class MyResidentPage extends ConsumerStatefulWidget {
  const MyResidentPage({super.key});

  @override
  ConsumerState<MyResidentPage> createState() => _MyResidentPageState();
}

class _MyResidentPageState extends ConsumerState<MyResidentPage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nikController;
  TextEditingController? _nameController;
  TextEditingController? _birthPlaceController;
  TextEditingController? _occupationController;
  TextEditingController? _educationController;
  String? _gender;
  String? _religion;
  String? _maritalStatus;
  DateTime? _birthDate;

  @override
  void dispose() {
    _nikController?.dispose();
    _nameController?.dispose();
    _birthPlaceController?.dispose();
    _occupationController?.dispose();
    _educationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final residentAsync = ref.watch(meResidentProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Data Diri Saya'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meResidentProvider),
        child: residentAsync.when(
          data: (resident) {
            if (resident == null) return _buildNoResident();
            return _buildContent(resident);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(e.toString()),
        ),
      ),
    );
  }

  Widget _buildContent(dynamic resident) {
    if (!_isEditing) {
      _initEditControllers(resident);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(resident),
            const SizedBox(height: 20),
            _buildInfoCard(resident),
            const SizedBox(height: 20),
            _isEditing ? _buildEditForm() : const SizedBox.shrink(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isEditing ? _saveChanges : _startEditing,
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Ubah Data'),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _initEditControllers(dynamic resident) {
    _nikController ??= TextEditingController(text: resident.nik);
    _nameController ??= TextEditingController(text: resident.fullName);
    _birthPlaceController ??= TextEditingController(
      text: resident.birthPlace ?? '',
    );
    _occupationController ??= TextEditingController(
      text: resident.occupation ?? '',
    );
    _educationController ??= TextEditingController(
      text: resident.lastEducation ?? '',
    );
    _gender ??= resident.gender;
    _religion ??= resident.religion;
    _maritalStatus ??= resident.maritalStatus;
    if (resident.birthDate != null) {
      try {
        _birthDate = DateTime.parse(resident.birthDate!);
      } catch (_) {}
    }
  }

  void _startEditing() {
    final resident = ref.read(meResidentProvider).valueOrNull;
    if (resident == null) return;
    _initEditControllers(resident);
    setState(() => _isEditing = true);
  }

  Widget _buildHeader(dynamic resident) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                resident.fullName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resident.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    resident.status,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(dynamic resident) {
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
          const Text(
            'Informasi Pribadi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('NIK', resident.nik),
          _infoRow('Nama Lengkap', resident.fullName),
          if (resident.birthPlace != null)
            _infoRow(
              'Tempat/Tgl Lahir',
              '${resident.birthPlace}${resident.birthDate != null ? ', ${resident.birthDate}' : ''}',
            ),
          _infoRow('Jenis Kelamin', resident.genderLabel),
          if (resident.religion != null)
            _infoRow('Agama', resident.religionLabel),
          _infoRow('Status Pernikahan', resident.maritalStatusLabel),
          if (resident.occupation != null)
            _infoRow('Pekerjaan', resident.occupation!),
          if (resident.lastEducation != null)
            _infoRow('Pendidikan', resident.lastEducation!),
          if (resident.phone != null) _infoRow('Telepon', resident.phone!),
          if (resident.email != null) _infoRow('Email', resident.email!),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
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
          const Text(
            'Ubah Data',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nikController,
            decoration: const InputDecoration(
              labelText: 'NIK *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'NIK wajib diisi' : null,
          ),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthPlaceController,
            decoration: const InputDecoration(
              labelText: 'Tempat Lahir',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _dateField(
            'Tanggal Lahir',
            _birthDate,
            (d) => setState(() => _birthDate = d),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Jenis Kelamin *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
              DropdownMenuItem(value: 'female', child: Text('Perempuan')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? _gender),
            validator: (v) => v == null ? 'Jenis kelamin wajib dipilih' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _religion,
            decoration: const InputDecoration(
              labelText: 'Agama',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'islam', child: Text('Islam')),
              DropdownMenuItem(value: 'kristen', child: Text('Kristen')),
              DropdownMenuItem(value: 'katolik', child: Text('Katolik')),
              DropdownMenuItem(value: 'hindu', child: Text('Hindu')),
              DropdownMenuItem(value: 'buddha', child: Text('Buddha')),
              DropdownMenuItem(value: 'konghucu', child: Text('Konghucu')),
            ],
            onChanged: (v) => setState(() => _religion = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: const InputDecoration(
              labelText: 'Status Pernikahan *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'single', child: Text('Belum Menikah')),
              DropdownMenuItem(value: 'married', child: Text('Menikah')),
              DropdownMenuItem(value: 'divorced', child: Text('Cerai')),
              DropdownMenuItem(value: 'widowed', child: Text('Duda/Janda')),
            ],
            onChanged: (v) =>
                setState(() => _maritalStatus = v ?? _maritalStatus),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _occupationController,
            decoration: const InputDecoration(
              labelText: 'Pekerjaan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _educationController,
            decoration: const InputDecoration(
              labelText: 'Pendidikan Terakhir',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    void Function(DateTime?) onChanged,
  ) {
    return InkWell(
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
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final ds = ref.read(meResidentDataSourceProvider);
      final body = <String, dynamic>{
        'nik': _nikController!.text.trim(),
        'full_name': _nameController!.text.trim(),
        'gender': _gender!,
        'marital_status': _maritalStatus!,
      };
      if (_birthPlaceController!.text.isNotEmpty) {
        body['birth_place'] = _birthPlaceController!.text.trim();
      }
      if (_birthDate != null) {
        body['birth_date'] = _birthDate!.toIso8601String().split('T').first;
      }
      if (_religion != null) body['religion'] = _religion;
      if (_occupationController!.text.isNotEmpty) {
        body['occupation'] = _occupationController!.text.trim();
      }
      if (_educationController!.text.isNotEmpty) {
        body['last_education'] = _educationController!.text.trim();
      }
      await ds.updateMeResident(body);
      ref.invalidate(meResidentProvider);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diperbarui'),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResident() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: AppColors.grey),
            SizedBox(height: 16),
            Text(
              'Anda belum terdaftar sebagai warga',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hubungi RT untuk didaftarkan',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gagal memuat data',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

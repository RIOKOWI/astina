import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/admin_resident_model.dart';
import '../../providers/household_admin_provider.dart';
import '../../providers/resident_admin_provider.dart';

class HouseholdFormPage extends ConsumerStatefulWidget {
  final int? householdId;

  const HouseholdFormPage({super.key, this.householdId});

  @override
  ConsumerState<HouseholdFormPage> createState() => _HouseholdFormPageState();
}

class _HouseholdFormPageState extends ConsumerState<HouseholdFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _noKkController = TextEditingController();
  final _addressController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _residentSearchController = SearchController();
  String _status = 'active';
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<AdminResidentListItem> _residentResults = [];
  AdminResidentListItem? _selectedResident;
  bool _isSearchingResidents = false;

  bool get isEditing => widget.householdId != null;

  @override
  void initState() {
    super.initState();
    _residentSearchController.addListener(_onResidentSearchChanged);
    if (isEditing) {
      _isLoading = true;
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    try {
      final ds = ref.read(householdAdminDataSourceProvider);
      final household = await ds.getHousehold(widget.householdId!);
      if (mounted) {
        setState(() {
          _noKkController.text = household.noKk;
          _addressController.text = household.address;
          _rtController.text = household.rt;
          _rwController.text = household.rw;
          _postalCodeController.text = household.postalCode ?? '';
          _status = household.status;
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

  Future<void> _onResidentSearchChanged() async {
    final query = _residentSearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _residentResults = [];
        _residentSearchController.clear();
      });
      return;
    }
    if (_isSearchingResidents) return;
    setState(() => _isSearchingResidents = true);
    try {
      final ds = ref.read(residentAdminDataSourceProvider);
      final (list, _) = await ds.getResidents(search: query, page: 1);
      if (mounted) {
        setState(() {
          _residentResults = list;
          _isSearchingResidents = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingResidents = false);
    }
  }

  void _selectResident(AdminResidentListItem resident) {
    setState(() {
      _selectedResident = resident;
      _residentResults = [];
      _residentSearchController.text = '${resident.fullName} (${resident.nik})';
    });
  }

  void _clearResident() {
    setState(() {
      _selectedResident = null;
      _residentSearchController.clear();
    });
  }

  @override
  void dispose() {
    _noKkController.dispose();
    _addressController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _postalCodeController.dispose();
    _residentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Keluarga' : 'Tambah Keluarga'),
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
                  _textField(_noKkController, 'No. KK', required: true),
                  _buildResidentPicker(),
                  _textField(
                    _addressController,
                    'Alamat',
                    required: true,
                    maxLines: 3,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _textField(_rtController, 'RT', required: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(_rwController, 'RW', required: true),
                      ),
                    ],
                  ),
                  _textField(_postalCodeController, 'Kode Pos'),
                  if (isEditing)
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Nonaktif'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
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

  Widget _buildResidentPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _residentSearchController,
            decoration: InputDecoration(
              labelText: 'Kepala Keluarga (Warga) *',
              border: const OutlineInputBorder(),
              suffixIcon: _selectedResident != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearResident,
                    )
                  : _isSearchingResidents
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
            ),
            onChanged: (_) => _onResidentSearchChanged(),
          ),
          if (_residentResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _residentResults.length,
                itemBuilder: (ctx, i) {
                  final r = _residentResults[i];
                  return ListTile(
                    dense: true,
                    title: Text(r.fullName),
                    subtitle: Text('NIK: ${r.nik}'),
                    trailing: Text(
                      r.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: r.status == 'active'
                            ? AppColors.success
                            : AppColors.grey,
                      ),
                    ),
                    onTap: () => _selectResident(r),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isEditing && _selectedResident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kepala Keluarga wajib dipilih'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(householdAdminDataSourceProvider);
      final body = <String, dynamic>{
        'no_kk': _noKkController.text.trim(),
        'address': _addressController.text.trim(),
        'rt': _rtController.text.trim(),
        'rw': _rwController.text.trim(),
        if (_postalCodeController.text.isNotEmpty)
          'postal_code': _postalCodeController.text.trim(),
      };
      if (isEditing) {
        body['status'] = _status;
        await ds.updateHousehold(widget.householdId!, body);
      } else {
        body['head_resident_id'] = _selectedResident!.id;
        await ds.createHousehold(body);
      }

      ref.invalidate(householdsListProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Keluarga berhasil diperbarui'
                  : 'Keluarga berhasil ditambahkan',
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

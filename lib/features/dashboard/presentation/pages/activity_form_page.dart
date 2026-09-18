import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../data/models/activity_model.dart';
import '../../providers/activity_provider.dart';

class ActivityFormPage extends ConsumerStatefulWidget {
  final int? activityId;

  const ActivityFormPage({super.key, this.activityId});

  @override
  ConsumerState<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends ConsumerState<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  DateTime? _startAt;
  DateTime? _endAt;
  String? _status;
  bool _isLoading = false;
  String? _errorMsg;
  Activity? _existing;

  bool get _isEdit => widget.activityId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _locationController = TextEditingController();
    if (_isEdit) {
      Future.microtask(_loadExisting);
    }
  }

  Future<void> _loadExisting() async {
    try {
      final a = await ref
          .read(activityDataSourceProvider)
          .getActivity(widget.activityId!);
      if (mounted) {
        setState(() {
          _existing = a;
          _titleController.text = a.title;
          _descController.text = a.description ?? '';
          _locationController.text = a.location ?? '';
          _startAt = a.startAt;
          _endAt = a.endAt;
          _status = a.status;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = friendlyErrorMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startAt = dt;
      } else {
        _endAt = dt;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startAt == null) {
      setState(() => _errorMsg = 'Waktu mulai wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final ds = ref.read(activityDataSourceProvider);
      final startStr =
          '${_startAt!.year}-${_startAt!.month.toString().padLeft(2, '0')}-${_startAt!.day.toString().padLeft(2, '0')} ${_startAt!.hour.toString().padLeft(2, '0')}:${_startAt!.minute.toString().padLeft(2, '0')}:00';
      final endStr = _endAt != null
          ? '${_endAt!.year}-${_endAt!.month.toString().padLeft(2, '0')}-${_endAt!.day.toString().padLeft(2, '0')} ${_endAt!.hour.toString().padLeft(2, '0')}:${_endAt!.minute.toString().padLeft(2, '0')}:00'
          : null;

      if (_isEdit) {
        await ds.updateActivity(
          widget.activityId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          startAt: startStr,
          endAt: endStr,
          status: _status,
        );
      } else {
        await ds.createActivity(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          startAt: startStr,
          endAt: endStr,
          status: _status ?? 'draft',
        );
      }
      ref.invalidate(activitiesListProvider);
      if (mounted) {
        context.go('/activities');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Aktivitas berhasil diperbarui'
                  : 'Aktivitas berhasil dibuat',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Aktivitas' : 'Buat Aktivitas'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: _isEdit && _existing == null
          ? _errorMsg != null
                ? Center(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  )
                : const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppColors.error),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Lokasi'),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildCard([
                      const Text(
                        'Waktu & Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeTile(
                        label: 'Waktu Mulai *',
                        value: _startAt != null
                            ? _formatDateTime(_startAt!)
                            : null,
                        onTap: () => _selectDateTime(true),
                        onClear: _startAt != null
                            ? () => setState(() => _startAt = null)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _buildDateTimeTile(
                        label: 'Waktu Selesai',
                        value: _endAt != null ? _formatDateTime(_endAt!) : null,
                        onTap: () => _selectDateTime(false),
                        onClear: _endAt != null
                            ? () => setState(() => _endAt = null)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('Dipublikasi'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Dibatalkan'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Selesai'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _status = v),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Buat Aktivitas',
                                style: const TextStyle(
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

  Widget _buildDateTimeTile({
    required String label,
    String? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.dark.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null ? AppColors.dark : AppColors.grey,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18, color: AppColors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

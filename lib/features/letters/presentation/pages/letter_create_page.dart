import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/letter_type_model.dart';
import '../../providers/letter_provider.dart';

class LetterCreatePage extends ConsumerStatefulWidget {
  const LetterCreatePage({super.key});

  @override
  ConsumerState<LetterCreatePage> createState() => _LetterCreatePageState();
}

class _LetterCreatePageState extends ConsumerState<LetterCreatePage> {
  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(letterTypesProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Ajukan Surat'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: typesAsync.when(
        data: (types) {
          if (types.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Tidak ada jenis surat tersedia.\nHubungi RT untuk informasi lebih lanjut.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
            );
          }
          return _buildForm(types);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat jenis surat: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<LetterType> types) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LetterSection('Jenis Surat', [
          ...types.map((type) => _buildTypeCard(type)),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTypeCard(LetterType type) {
    return GestureDetector(
      onTap: () => _showSubmissionSheet(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  if (type.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      type.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  void _showSubmissionSheet(LetterType type) async {
    // Fetch detail to get complete fields (list response does not include fields)
    LetterType detailedType;
    try {
      detailedType = await ref
          .read(letterTypeDetailProvider(type.id).future);
    } catch (_) {
      detailedType = type;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LetterSubmissionSheet(
        letterType: detailedType,
        onSuccess: () {
          ref.invalidate(
            myLettersProvider((status: null, letterTypeId: null, page: 1)),
          );
          context.go('/letters');
        },
      ),
    );
  }
}

class LetterSubmissionSheet extends ConsumerStatefulWidget {
  final LetterType letterType;
  final VoidCallback onSuccess;

  const LetterSubmissionSheet({
    super.key,
    required this.letterType,
    required this.onSuccess,
  });

  @override
  ConsumerState<LetterSubmissionSheet> createState() =>
      _LetterSubmissionSheetState();
}

class _LetterSubmissionSheetState extends ConsumerState<LetterSubmissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.letterType.fields) {
      _controllers[field.fieldKey] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.letterType.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              if (widget.letterType.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.letterType.description!,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
              const SizedBox(height: 20),
              ...widget.letterType.fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFieldInput(field),
                ),
              ),
              TextFormField(
                controller: _purposeController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Keperluan / Keterangan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
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
                      : const Text(
                          'Kirim Pengajuan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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

  Widget _buildFieldInput(LetterTypeField field) {
    final ctrl = _controllers[field.fieldKey]!;

    switch (field.fieldType) {
      case 'textarea':
        return TextFormField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          validator: field.isRequired
              ? (v) =>
                    v == null || v.isEmpty ? '${field.label} wajib diisi' : null
              : null,
        );
      case 'date':
        return TextFormField(
          controller: ctrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? ' *' : ''}',
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today, size: 20),
          ),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1940),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) {
              ctrl.text =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            }
          },
          validator: field.isRequired
              ? (v) =>
                    v == null || v.isEmpty ? '${field.label} wajib diisi' : null
              : null,
        );
      case 'number':
        return TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          validator: field.isRequired
              ? (v) =>
                    v == null || v.isEmpty ? '${field.label} wajib diisi' : null
              : null,
        );
      case 'select':
        final isGenderField = field.fieldKey.contains('jenis_kelamin') ||
            field.label.toLowerCase().contains('jenis kelamin');
        final selectItems = isGenderField
            ? ['Laki-Laki', 'Perempuan']
            : <String>[];
        return DropdownButtonFormField<String>(
          value: ctrl.text.isEmpty ? null : ctrl.text,
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('-- Pilih --')),
            ...selectItems.map(
              (v) => DropdownMenuItem(value: v, child: Text(v)),
            ),
          ],
          onChanged: (v) => ctrl.text = v ?? '',
          validator: field.isRequired
              ? (v) =>
                    v == null || v.isEmpty ? '${field.label} wajib diisi' : null
              : null,
        );
      default:
        return TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: '${field.label}${field.isRequired ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          validator: field.isRequired
              ? (v) =>
                    v == null || v.isEmpty ? '${field.label} wajib diisi' : null
              : null,
        );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final fields = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      if (entry.value.text.isNotEmpty) {
        // Always send as String — backend validates all field values as string
        fields[entry.key] = entry.value.text;
      }
    }

    try {
      final ds = ref.read(letterRemoteDataSourceProvider);
      await ds.createLetter(
        letterTypeId: widget.letterType.id,
        purpose: _purposeController.text.isNotEmpty
            ? _purposeController.text
            : null,
        fields: fields,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan surat berhasil dikirim'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ??
          e.message ??
          'Gagal mengirim pengajuan';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
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

class LetterSection extends StatelessWidget {
  const LetterSection(this.title, this.children, {super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

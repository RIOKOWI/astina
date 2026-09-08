import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/letter_type_model.dart';
import '../../providers/letter_provider.dart';

class CreateLetterPage extends ConsumerStatefulWidget {
  final int letterTypeId;

  const CreateLetterPage({super.key, required this.letterTypeId});

  @override
  ConsumerState<CreateLetterPage> createState() => _CreateLetterPageState();
}

class _CreateLetterPageState extends ConsumerState<CreateLetterPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _fieldValues = {};
  final _purposeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeAsync = ref.watch(letterTypeDetailProvider(widget.letterTypeId));

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Ajukan Surat'),
      ),
      body: typeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (type) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeHeader(type),
                const SizedBox(height: 20),
                _buildDynamicFields(type.fields ?? []),
                const SizedBox(height: 16),
                _buildPurposeField(),
                const SizedBox(height: 24),
                _buildSubmitButton(type),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeHeader(LetterTypeModel type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (type.description != null && type.description!.isNotEmpty)
                  Text(
                    type.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFields(List<LetterFieldModel> fields) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Isi Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '* Wajib diisi',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          ...fields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildFieldInput(field),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInput(LetterFieldModel field) {
    switch (field.fieldType) {
      case 'textarea':
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
            hintText: 'Masukkan ${field.label.toLowerCase()}',
          ),
          maxLines: 3,
          validator: field.isRequired
              ? (val) => val == null || val.isEmpty
                    ? '${field.label} wajib diisi'
                    : null
              : null,
          onSaved: (val) => _fieldValues[field.fieldKey] = val ?? '',
        );
      case 'date':
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
            hintText: 'YYYY-MM-DD',
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          readOnly: true,
          controller: TextEditingController(
            text: _fieldValues[field.fieldKey]?.toString() ?? '',
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(
                () => _fieldValues[field.fieldKey] =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              );
            }
          },
          validator: field.isRequired
              ? (val) => val == null || val.isEmpty
                    ? '${field.label} wajib diisi'
                    : null
              : null,
        );
      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
          ),
          value: _fieldValues[field.fieldKey] as String?,
          items: (field.options ?? [])
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) =>
              setState(() => _fieldValues[field.fieldKey] = val ?? ''),
          validator: field.isRequired
              ? (val) => val == null || val.isEmpty
                    ? '${field.label} wajib diisi'
                    : null
              : null,
        );
      case 'checkbox':
        return CheckboxListTile(
          title: Text(field.label, style: AppTextStyles.body),
          subtitle: field.isRequired
              ? const Text(
                  '* Wajib diisi',
                  style: TextStyle(fontSize: 11, color: AppColors.grey),
                )
              : null,
          value: _fieldValues[field.fieldKey] == true,
          onChanged: (val) =>
              setState(() => _fieldValues[field.fieldKey] = val ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      case 'number':
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
            hintText: 'Masukkan angka',
          ),
          keyboardType: TextInputType.number,
          validator: field.isRequired
              ? (val) => val == null || val.isEmpty
                    ? '${field.label} wajib diisi'
                    : null
              : null,
          onSaved: (val) => _fieldValues[field.fieldKey] = val ?? '',
        );
      default:
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
            hintText: 'Masukkan ${field.label.toLowerCase()}',
          ),
          validator: field.isRequired
              ? (val) => val == null || val.isEmpty
                    ? '${field.label} wajib diisi'
                    : null
              : null,
          onSaved: (val) => _fieldValues[field.fieldKey] = val ?? '',
        );
    }
  }

  Widget _buildPurposeField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tujuan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Opsional - jelaskan mengapa mengajukan surat ini',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _purposeController,
            decoration: const InputDecoration(
              hintText: 'Contoh: Untuk pengurusan KTP, passport, dll',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(LetterTypeModel type) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _submitLetter(type),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Kirim Pengajuan'),
      ),
    );
  }

  Future<void> _submitLetter(LetterTypeModel type) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(letterNotifierProvider.notifier)
        .submitLetter(
          letterTypeId: widget.letterTypeId,
          fields: Map<String, dynamic>.from(_fieldValues),
          purpose: _purposeController.text.isNotEmpty
              ? _purposeController.text
              : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan surat berhasil dikirim!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/letters');
    } else {
      final err = ref.read(letterNotifierProvider).valueOrNull?.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${err ?? 'Coba lagi'}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

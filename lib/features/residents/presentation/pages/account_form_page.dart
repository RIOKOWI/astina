import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/resident_admin_provider.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  final int residentId;

  const AccountFormPage({super.key, required this.residentId});

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String _residentName = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final ds = ref.read(residentAdminDataSourceProvider);
      final resident = await ds.getResident(widget.residentId);
      if (mounted) {
        setState(() {
          _residentName = resident.fullName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data warga: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Buat Akun Warga'),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Akun untuk',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              Text(
                                _residentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection('Informasi Akun', [
                    _textField(
                      _phoneController,
                      'Nomor HP',
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),
                    _textField(
                      _emailController,
                      'Email',
                      keyboardType: TextInputType.emailAddress,
                      required: true,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Kata Sandi', [
                    _passwordField(
                      _passwordController,
                      'Kata Sandi',
                      _obscurePassword,
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      required: true,
                    ),
                    _passwordField(
                      _confirmController,
                      'Konfirmasi Kata Sandi',
                      _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                      required: true,
                      confirmOf: _passwordController.text,
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.grey,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Password minimal 8 karakter. Role warga akan diberikan secara otomatis.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          : const Text(
                              'Simpan',
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
    );
  }

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
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
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

  Widget _passwordField(
    TextEditingController ctrl,
    String label,
    bool obscured,
    VoidCallback onToggle, {
    bool required = false,
    String? confirmOf,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscured,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(obscured ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggle,
          ),
        ),
        validator: required
            ? (v) {
                if (v == null || v.isEmpty) return '$label wajib diisi';
                if (confirmOf != null && v != confirmOf) {
                  return 'Konfirmasi kata sandi tidak cocok';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(residentAdminDataSourceProvider);
      await ds.createAccount(widget.residentId, {
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _confirmController.text,
      });

      ref.invalidate(residentDetailProvider(widget.residentId));
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun warga berhasil dibuat'),
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
          if (errors != null && errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final errList = errors[firstKey];
            if (errList is List && errList.isNotEmpty) {
              message = errList.first.toString();
            } else if (errList is String) {
              message = errList;
            } else {
              message = data['message']?.toString() ?? message;
            }
          }
        }
      } else if (e.response?.statusCode == 409) {
        message = 'Warga ini sudah memiliki akun.';
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/admin_resident_model.dart';
import '../../providers/resident_admin_provider.dart';

class ResidentDetailPage extends ConsumerWidget {
  final int residentId;

  const ResidentDetailPage({super.key, required this.residentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(residentDetailProvider(residentId));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Warga'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/residents/$residentId/edit'),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (resident) => _buildContent(context, ref, resident),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AdminResident r) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(residentDetailProvider(residentId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(r),
            const SizedBox(height: 20),
            _buildInfoCard('Data Pribadi', [
              _infoRow('NIK', r.nik),
              _infoRow('Nama Lengkap', r.fullName),
              if (r.birthPlace != null)
                _infoRow(
                  'Tempat Lahir',
                  '${r.birthPlace}${r.birthDate != null ? ', ${r.birthDate}' : ''}',
                ),
              if (r.gender != null)
                _infoRow(
                  'Jenis Kelamin',
                  r.gender == 'male' ? 'Laki-laki' : 'Perempuan',
                ),
              if (r.religion != null) _infoRow('Agama', r.religion ?? '-'),
              if (r.maritalStatus != null)
                _infoRow('Status Pernikahan', _maritalLabel(r.maritalStatus!)),
              if (r.occupation != null) _infoRow('Pekerjaan', r.occupation!),
              if (r.lastEducation != null)
                _infoRow('Pendidikan Terakhir', r.lastEducation!),
              _infoRow('Status', r.status),
            ]),
            const SizedBox(height: 16),
            if (r.phone != null || r.email != null)
              _buildInfoCard('Kontak', [
                if (r.phone != null) _infoRow('Telepon', r.phone!),
                if (r.email != null) _infoRow('Email', r.email!),
              ]),
            if (r.household != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Keluarga', [
                _infoRow('No. KK', r.household!.noKk),
                _infoRow('Alamat', r.household!.address),
                _infoRow(
                  'RT/RW',
                  'RT ${r.household!.rt} / RW ${r.household!.rw}',
                ),
              ]),
            ],
            if (r.account != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Akun Aplikasi', [
                _infoRow(
                  'Status Akun',
                  r.account!.isActive ? 'Aktif' : 'Nonaktif',
                ),
                if (r.account!.phone != null)
                  _infoRow('Telepon', r.account!.phone!),
                if (r.account!.email != null)
                  _infoRow('Email', r.account!.email!),
                if (r.account!.lastLoginAt != null)
                  _infoRow(
                    'Login Terakhir',
                    _formatDate(r.account!.lastLoginAt!),
                  ),
                if (r.account!.roles != null && r.account!.roles!.isNotEmpty)
                  _infoRow(
                    'Role',
                    r.account!.roles!.map((role) => role.name).join(', '),
                  ),
              ]),
            ],
            const SizedBox(height: 16),
            _buildInfoCard('Dokumen', [
              _docRow('KTP', r.ktp),
              _docRow('KK', r.kk),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AdminResident r) {
    final statusColor = switch (r.status) {
      'active' => AppColors.success,
      'inactive' => AppColors.warning,
      'moved' => AppColors.grey,
      _ => AppColors.grey,
    };
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
                r.fullName.substring(0, 1).toUpperCase(),
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
                  r.fullName,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
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

  Widget _buildInfoCard(String title, List<Widget> rows) {
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
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Widget _docRow(String label, AdminResidentDoc? doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ),
          if (doc != null && doc.exists)
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  doc.fileName ?? 'Tersedia',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Belum diupload',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
        ],
      ),
    );
  }

  String _maritalLabel(String status) {
    switch (status) {
      case 'single':
        return 'Belum Menikah';
      case 'married':
        return 'Menikah';
      case 'divorced':
        return 'Cerai';
      case 'widowed':
        return 'Duda/Janda';
      default:
        return status;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/rt_admin_provider.dart';

class ResidentListPage extends ConsumerStatefulWidget {
  const ResidentListPage({super.key});

  @override
  ConsumerState<ResidentListPage> createState() => _ResidentListPageState();
}

class _ResidentListPageState extends ConsumerState<ResidentListPage> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  bool? _hasAccount;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = RtResidentFilter(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      status: _selectedStatus,
      hasAccount: _hasAccount,
    );
    final residentsAsync = ref.watch(rtResidentsProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Daftar Warga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/rt-admin/residents/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: residentsAsync.when(
              loading: () => _buildSkeleton(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (residents) {
                if (residents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: AppColors.grey),
                        const SizedBox(height: 16),
                        const Text('Tidak ada data warga'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(rtResidentsProvider(filter)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: residents.length,
                    itemBuilder: (context, index) {
                      final r = residents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              r.fullName[0].toUpperCase(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            r.fullName,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NIK: ${r.nik ?? '-'}',
                                style: AppTextStyles.bodySmall,
                              ),
                              if (r.phone != null)
                                Text(
                                  'Telp: ${r.phone}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (r.hasAccount)
                                Icon(
                                  Icons.account_circle,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    r.status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  r.statusLabel,
                                  style: TextStyle(
                                    color: _statusColor(r.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () =>
                              context.push('/rt-admin/residents/${r.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIK...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickFilter(
                  label: 'Semua',
                  selected: _selectedStatus == null && _hasAccount == null,
                  onTap: () => setState(() {
                    _selectedStatus = null;
                    _hasAccount = null;
                  }),
                ),
                const SizedBox(width: 6),
                _QuickFilter(
                  label: 'Aktif',
                  selected: _selectedStatus == 'active',
                  onTap: () => setState(() {
                    _selectedStatus = 'active';
                  }),
                ),
                const SizedBox(width: 6),
                _QuickFilter(
                  label: 'Ada Akun',
                  selected: _hasAccount == true,
                  onTap: () => setState(() {
                    _hasAccount = true;
                    _selectedStatus = null;
                  }),
                ),
                const SizedBox(width: 6),
                _QuickFilter(
                  label: 'Tanpa Akun',
                  selected: _hasAccount == false,
                  onTap: () => setState(() {
                    _hasAccount = false;
                    _selectedStatus = null;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.grey;
      case 'moved':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }
}

class _QuickFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.dark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

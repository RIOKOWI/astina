import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/rt_admin_provider.dart';

class RtAdminHubPage extends ConsumerStatefulWidget {
  const RtAdminHubPage({super.key});

  @override
  ConsumerState<RtAdminHubPage> createState() => _RtAdminHubPageState();
}

class _RtAdminHubPageState extends ConsumerState<RtAdminHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Administrasi RT'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Warga'),
            Tab(text: 'KK'),
            Tab(text: 'Akun'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ResidentsTab(), _HouseholdsTab(), _UsersTab()],
      ),
    );
  }
}

class _ResidentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.push('/rt-admin/residents/create'),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Warga'),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/rt-admin/residents'),
                  icon: const Icon(Icons.list, size: 20),
                  label: const Text('Lihat Daftar'),
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: _ResidentsList()),
      ],
    );
  }
}

class _ResidentsList extends ConsumerStatefulWidget {
  const _ResidentsList();

  @override
  ConsumerState<_ResidentsList> createState() => _ResidentsListState();
}

class _ResidentsListState extends ConsumerState<_ResidentsList> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final filter = RtResidentFilter(status: _selectedStatus);
    final residentsAsync = ref.watch(rtResidentsProvider(filter));

    return Column(
      children: [
        Container(
          color: AppColors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Aktif',
                  selected: _selectedStatus == 'active',
                  onTap: () => setState(() => _selectedStatus = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Nonaktif',
                  selected: _selectedStatus == 'inactive',
                  onTap: () => setState(() => _selectedStatus = 'inactive'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pindah',
                  selected: _selectedStatus == 'moved',
                  onTap: () => setState(() => _selectedStatus = 'moved'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: residentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (residents) {
              if (residents.isEmpty) {
                return const Center(child: Text('Belum ada data warga'));
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
                        subtitle: Text(
                          'NIK: ${r.nik ?? '-'}',
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _HouseholdsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdsAsync = ref.watch(rtHouseholdsProvider);

    return Column(
      children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.push('/rt-admin/households/create'),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah KK'),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/rt-admin/households'),
                  icon: const Icon(Icons.list, size: 20),
                  label: const Text('Lihat Daftar'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: householdsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (households) {
              if (households.isEmpty) {
                return const Center(child: Text('Belum ada data KK'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(rtHouseholdsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: households.length,
                  itemBuilder: (context, index) {
                    final h = households[index];
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
                          child: Icon(Icons.home, color: AppColors.primary),
                        ),
                        title: Text(
                          h.noKk ?? '-',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (h.headResident != null)
                              Text(
                                'KK: ${h.headResident!.fullName}',
                                style: AppTextStyles.bodySmall,
                              ),
                            Text(
                              h.fullAddress,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${h.memberCount ?? 0} orang',
                          style: AppTextStyles.bodySmall,
                        ),
                        onTap: () =>
                            context.push('/rt-admin/households/${h.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => context.push('/rt-admin/users'),
            icon: const Icon(Icons.manage_accounts, size: 20),
            label: const Text('Kelola Akun'),
          ),
        ),
        const Expanded(child: _UsersList()),
      ],
    );
  }
}

class _UsersList extends ConsumerStatefulWidget {
  const _UsersList();

  @override
  ConsumerState<_UsersList> createState() => _UsersListState();
}

class _UsersListState extends ConsumerState<_UsersList> {
  bool? _isActive;

  @override
  Widget build(BuildContext context) {
    final filter = RtUserFilter(isActive: _isActive);
    final usersAsync = ref.watch(rtUsersProvider(filter));

    return Column(
      children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _isActive == null,
                  onTap: () => setState(() => _isActive = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Aktif',
                  selected: _isActive == true,
                  onTap: () => setState(() => _isActive = true),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Nonaktif',
                  selected: _isActive == false,
                  onTap: () => setState(() => _isActive = false),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: Text('Belum ada akun'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(rtUsersProvider(filter)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.grey.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            color: u.isActive
                                ? AppColors.success
                                : AppColors.grey,
                          ),
                        ),
                        title: Text(
                          u.resident?.fullName ?? u.phone,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(u.phone, style: AppTextStyles.bodySmall),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (u.isActive
                                        ? AppColors.success
                                        : AppColors.grey)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            u.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              color: u.isActive
                                  ? AppColors.success
                                  : AppColors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () => context.push('/rt-admin/users/${u.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.dark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

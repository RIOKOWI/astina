import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/rt_admin_provider.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  final _searchController = TextEditingController();
  bool? _isActive;
  String? _role;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = RtUserFilter(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      isActive: _isActive,
      role: _role,
    );
    final usersAsync = ref.watch(rtUsersProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Kelola Akun'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau telepon...',
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
                        selected: _isActive == null,
                        onTap: () => setState(() {
                          _isActive = null;
                          _role = null;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'Aktif',
                        selected: _isActive == true,
                        onTap: () => setState(() {
                          _isActive = true;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'Nonaktif',
                        selected: _isActive == false,
                        onTap: () => setState(() {
                          _isActive = false;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickFilter(
                        label: 'Semua Role',
                        selected: _role == null,
                        onTap: () => setState(() => _role = null),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'RT',
                        selected: _role == 'rt',
                        onTap: () => setState(() => _role = 'rt'),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'Bendahara',
                        selected: _role == 'bendahara',
                        onTap: () => setState(() => _role = 'bendahara'),
                      ),
                      const SizedBox(width: 6),
                      _QuickFilter(
                        label: 'Warga',
                        selected: _role == 'warga',
                        onTap: () => setState(() => _role = 'warga'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => _buildSkeleton(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: AppColors.grey),
                        const SizedBox(height: 16),
                        const Text('Belum ada akun'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(rtUsersProvider(filter)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/rt-admin/users/${u.id}'),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.resident?.fullName ?? u.phone,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        u.phone,
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      if (u.roles != null &&
                                          u.roles!.isNotEmpty)
                                        Text(
                                          u.rolesLabel,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
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
                              ],
                            ),
                          ),
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

  Widget _buildSkeleton() {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
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

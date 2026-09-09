import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/admin_user_model.dart';
import '../../providers/user_admin_provider.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();
  bool? _isActiveFilter;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() => ref
      .read(usersListProvider.notifier)
      .load(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        isActive: _isActiveFilter,
        role: _roleFilter,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('User Admin'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau no. HP...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => ref
                  .read(usersListProvider.notifier)
                  .load(
                    search: v.isEmpty ? null : v,
                    isActive: _isActiveFilter,
                    role: _roleFilter,
                  ),
            ),
          ),
          if (_isActiveFilter != null || _roleFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_isActiveFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_isActiveFilter! ? 'Aktif' : 'Nonaktif'),
                        onDeleted: () {
                          setState(() => _isActiveFilter = null);
                          _load();
                        },
                      ),
                    ),
                  if (_roleFilter != null)
                    Chip(
                      label: Text(_roleFilter!),
                      onDeleted: () {
                        setState(() => _roleFilter = null);
                        _load();
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: state.users.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.users.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.users.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        final u = state.users[index];
                        return _buildUserCard(u);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final statusColor = user.isActive ? AppColors.success : AppColors.grey;
    final statusLabel = user.isActive ? 'Aktif' : 'Nonaktif';
    return GestureDetector(
      onTap: () => context.push('/users/${user.id}'),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (user.resident?.fullName.substring(0, 1).toUpperCase() ??
                      user.phone.substring(0, 1).toUpperCase()),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.resident?.fullName ?? user.phone,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  if (user.roles.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: user.roles.map((r) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (user.lastLoginAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatLastLogin(user.lastLoginAt!),
                    style: const TextStyle(fontSize: 10, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastLogin(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}h lalu';
    if (diff.inHours > 0) return '${diff.inHours}j lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m lalu';
    return 'Baru';
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada user',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _isActiveFilter == null,
                  onSelected: (_) {
                    setState(() => _isActiveFilter = null);
                    Navigator.of(ctx).pop();
                    _load();
                  },
                ),
                ChoiceChip(
                  label: const Text('Aktif'),
                  selected: _isActiveFilter == true,
                  onSelected: (_) {
                    setState(() => _isActiveFilter = true);
                    Navigator.of(ctx).pop();
                    _load();
                  },
                ),
                ChoiceChip(
                  label: const Text('Nonaktif'),
                  selected: _isActiveFilter == false,
                  onSelected: (_) {
                    setState(() => _isActiveFilter = false);
                    Navigator.of(ctx).pop();
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Role',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _roleFilter == null,
                  onSelected: (_) {
                    setState(() => _roleFilter = null);
                    Navigator.of(ctx).pop();
                    _load();
                  },
                ),
                ChoiceChip(
                  label: const Text('RT'),
                  selected: _roleFilter == 'rt',
                  onSelected: (_) {
                    setState(() => _roleFilter = 'rt');
                    Navigator.of(ctx).pop();
                    _load();
                  },
                ),
                ChoiceChip(
                  label: const Text('Bendahara'),
                  selected: _roleFilter == 'bendahara',
                  onSelected: (_) {
                    setState(() => _roleFilter = 'bendahara');
                    Navigator.of(ctx).pop();
                    _load();
                  },
                ),
                ChoiceChip(
                  label: const Text('Warga'),
                  selected: _roleFilter == 'warga',
                  onSelected: (_) {
                    setState(() => _roleFilter = 'warga');
                    Navigator.of(ctx).pop();
                    _load();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

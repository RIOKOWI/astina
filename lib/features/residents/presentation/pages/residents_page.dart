import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../providers/resident_admin_provider.dart';

class ResidentsPage extends ConsumerStatefulWidget {
  const ResidentsPage({super.key});

  @override
  ConsumerState<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends ConsumerState<ResidentsPage> {
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(residentsListProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(residentsListProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Daftar Warga'),
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
                hintText: 'Cari nama atau NIK...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(residentsListProvider.notifier)
                              .load(search: null, status: _statusFilter);
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => ref
                  .read(residentsListProvider.notifier)
                  .load(search: v.isEmpty ? null : v, status: _statusFilter),
            ),
          ),
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text('Status: $_statusFilter'),
                    onDeleted: () {
                      setState(() => _statusFilter = null);
                      ref
                          .read(residentsListProvider.notifier)
                          .load(
                            search: _searchController.text.isEmpty
                                ? null
                                : _searchController.text,
                          );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(residentsListProvider.notifier)
                  .load(
                    search: _searchController.text.isEmpty
                        ? null
                        : _searchController.text,
                    status: _statusFilter,
                  ),
              child: state.residents.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          state.residents.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.residents.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        final r = state.residents[index];
                        return _buildResidentCard(r);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/residents/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildResidentCard(dynamic resident) {
    final statusColor = switch (resident.status) {
      'active' => AppColors.success,
      'inactive' => AppColors.warning,
      'moved' => AppColors.grey,
      _ => AppColors.grey,
    };
    return GestureDetector(
      onTap: () => context.push('/residents/${resident.id}'),
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
                  resident.fullName.substring(0, 1).toUpperCase(),
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
                    resident.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIK: ${resident.nik}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  if (resident.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      resident.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
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
                    resident.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (resident.hasAccount)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  )
                else
                  const Icon(Icons.person_off, size: 16, color: AppColors.grey),
              ],
            ),
          ],
        ),
      ),
    );
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
                'Belum ada data warga',
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
        title: const Text('Filter Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semua'),
              onTap: () {
                setState(() => _statusFilter = null);
                ref
                    .read(residentsListProvider.notifier)
                    .load(
                      search: _searchController.text.isEmpty
                          ? null
                          : _searchController.text,
                    );
                Navigator.of(ctx).pop();
              },
            ),
            ...(['active', 'inactive', 'moved'].map(
              (s) => ListTile(
                title: Text(s),
                onTap: () {
                  setState(() => _statusFilter = s);
                  ref
                      .read(residentsListProvider.notifier)
                      .load(
                        search: _searchController.text.isEmpty
                            ? null
                            : _searchController.text,
                        status: s,
                      );
                  Navigator.of(ctx).pop();
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}

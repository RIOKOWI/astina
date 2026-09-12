import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/activity_model.dart';
import '../../providers/activity_provider.dart';

class ActivitiesPage extends ConsumerStatefulWidget {
  const ActivitiesPage({super.key});

  @override
  ConsumerState<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends ConsumerState<ActivitiesPage> {
  final _searchController = TextEditingController();
  String? _statusFilter;

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
      .read(activitiesListProvider.notifier)
      .load(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _statusFilter,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activitiesListProvider);
    final role = ref.watch(currentUserRoleProvider);
    final isRT = role == UserRole.rt;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Aktivitas'),
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
                hintText: 'Cari aktivitas...',
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
                  .read(activitiesListProvider.notifier)
                  .load(search: v.isEmpty ? null : v, status: _statusFilter),
            ),
          ),
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(_filterLabel(_statusFilter!)),
                    onDeleted: () {
                      setState(() => _statusFilter = null);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: state.error != null
                  ? _buildError(state.error!)
                  : state.activities.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          state.activities.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.activities.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        final a = state.activities[index];
                        return _buildActivityCard(a);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: isRT
          ? FloatingActionButton(
              onPressed: () => context.push('/activities/create'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _filterLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'published':
        return 'Dipublikasi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  Widget _buildActivityCard(Activity activity) {
    final statusColor = switch (activity.status) {
      'published' => AppColors.success,
      'draft' => AppColors.warning,
      'cancelled' => AppColors.error,
      'completed' => AppColors.primary,
      _ => AppColors.grey,
    };
    return GestureDetector(
      onTap: () => context.push('/activities/${activity.id}'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
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
                    activity.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (activity.description != null) ...[
              const SizedBox(height: 4),
              Text(
                activity.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (activity.location != null) ...[
                  Icon(Icons.location_on, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (activity.startAt != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(activity.startAt!),
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
                if (activity.attachmentCount != null &&
                    activity.attachmentCount! > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.attach_file, size: 14, color: AppColors.grey),
                  const SizedBox(width: 2),
                  Text(
                    '${activity.attachmentCount}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.event_outlined, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada aktivitas',
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

  Widget _buildError(String msg) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat aktivitas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  friendlyErrorMessage(msg),
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    final statuses = ['draft', 'published', 'cancelled', 'completed'];
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
                Navigator.of(ctx).pop();
                _load();
              },
            ),
            ...statuses.map(
              (s) => ListTile(
                title: Text(_filterLabel(s)),
                onTap: () {
                  setState(() => _statusFilter = s);
                  Navigator.of(ctx).pop();
                  _load();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

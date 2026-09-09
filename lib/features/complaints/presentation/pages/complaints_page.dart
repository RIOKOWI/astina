import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/complaint_model.dart';
import '../../providers/complaint_provider.dart';

class ComplaintsPage extends ConsumerStatefulWidget {
  const ComplaintsPage({super.key});

  @override
  ConsumerState<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends ConsumerState<ComplaintsPage> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() => ref.read(complaintsListProvider.notifier).load(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _statusFilter,
        category: _categoryFilter,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complaintsListProvider);
    final role = ref.watch(currentUserRoleProvider);
    final isWarga = role == UserRole.warga;
    final myResidentId = ref.watch(authProvider).user?.resident?.id;
    // Jika response warga: backend sudah filter, resident tidak ada di tiap item.
    // Jika response RT: tampilkan semua.
    final hasResidents = state.complaints.isNotEmpty &&
        state.complaints.first.resident != null;
    final complaints = isWarga && myResidentId != null && hasResidents
        ? state.complaints.where((c) => c.residentId == myResidentId).toList()
        : state.complaints;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Pengaduan'),
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
                hintText: 'Cari pengaduan...',
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
                  .read(complaintsListProvider.notifier)
                  .load(
                    search: v.isEmpty ? null : v,
                    status: _statusFilter,
                    category: _categoryFilter,
                  ),
            ),
          ),
          if (_statusFilter != null || _categoryFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_statusFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_statusLabel(_statusFilter!)),
                        onDeleted: () {
                          setState(() => _statusFilter = null);
                          _load();
                        },
                      ),
                    ),
                  if (_categoryFilter != null)
                    Chip(
                      label: Text(_categoryLabel(_categoryFilter!)),
                      onDeleted: () {
                        setState(() => _categoryFilter = null);
                        _load();
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: complaints.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: complaints.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == complaints.length) {
                          if (state.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return _ComplaintCard(
                          complaint: complaints[index],
                          onTap: () => context
                              .push('/complaints/${complaints[index].id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: isWarga
          ? FloatingActionButton(
              onPressed: () => context.push('/complaints/create'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.report_outlined, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada pengaduan',
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

  String _statusLabel(String s) {
    switch (s) {
      case 'submitted':
        return 'Baru';
      case 'reviewed':
        return 'Ditinjau';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      case 'closed':
        return 'Ditutup';
      case 'rejected':
        return 'Ditolak';
      default:
        return s;
    }
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'facility':
        return 'Fasilitas';
      case 'security':
        return 'Keamanan';
      case 'cleanliness':
        return 'Kebersihan';
      case 'noise':
        return 'Kebisingan';
      case 'dispute':
        return 'Perselisihan';
      case 'other':
        return 'Lainnya';
      default:
        return c;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('Semua', null, (v) => setState(() => _statusFilter = v)),
                _filterChip('Baru', 'submitted', (v) => setState(() => _statusFilter = v)),
                _filterChip('Ditinjau', 'reviewed', (v) => setState(() => _statusFilter = v)),
                _filterChip('Diproses', 'in_progress', (v) => setState(() => _statusFilter = v)),
                _filterChip('Selesai', 'resolved', (v) => setState(() => _statusFilter = v)),
                _filterChip('Ditutup', 'closed', (v) => setState(() => _statusFilter = v)),
                _filterChip('Ditolak', 'rejected', (v) => setState(() => _statusFilter = v)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('Semua', null, (v) => setState(() => _categoryFilter = v)),
                _filterChip('Fasilitas', 'facility', (v) => setState(() => _categoryFilter = v)),
                _filterChip('Keamanan', 'security', (v) => setState(() => _categoryFilter = v)),
                _filterChip('Kebersihan', 'cleanliness', (v) => setState(() => _categoryFilter = v)),
                _filterChip('Kebisingan', 'noise', (v) => setState(() => _categoryFilter = v)),
                _filterChip('Perselisihan', 'dispute', (v) => setState(() => _categoryFilter = v)),
                _filterChip('Lainnya', 'other', (v) => setState(() => _categoryFilter = v)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _load();
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, void Function(String?) onSelected) {
    final isSelected = (value == null && _statusFilter == null && _categoryFilter == null) == false;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected && (_statusFilter == value || _categoryFilter == value),
      onSelected: (_) => onSelected(value),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, required this.onTap});

  final Complaint complaint;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (complaint.status) {
      case 'submitted':
        return AppColors.primary;
      case 'reviewed':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.grey;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                    complaint.referenceNo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    complaint.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            if (complaint.description != null) ...[
              const SizedBox(height: 4),
              Text(
                complaint.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    complaint.categoryLabel,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ),
                if (complaint.resident != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.person, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    complaint.resident!.fullName,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
                if (complaint.attachmentCount != null && complaint.attachmentCount! > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.attach_file, size: 14, color: AppColors.grey),
                  const SizedBox(width: 2),
                  Text(
                    '${complaint.attachmentCount}',
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
}

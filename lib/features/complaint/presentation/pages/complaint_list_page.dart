import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/complaint_provider.dart';
import '../../data/models/complaint_model.dart';

class ComplaintListPage extends ConsumerStatefulWidget {
  const ComplaintListPage({super.key});

  @override
  ConsumerState<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends ConsumerState<ComplaintListPage> {
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(
      filteredComplaintsProvider((
        status: _selectedStatus,
        category: _selectedCategory,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pengaduan Saya'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/complaints/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: complaintsAsync.when(
              loading: () => _buildSkeleton(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (complaints) {
                if (complaints.isEmpty) {
                  return const Center(child: Text('Belum ada pengaduan'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    filteredComplaintsProvider((
                      status: _selectedStatus,
                      category: _selectedCategory,
                    )),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      return _ComplaintCard(
                        complaint: complaints[index],
                        onTap: () =>
                            context.push('/complaints/${complaints[index].id}'),
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown(
              label: 'Status',
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: 'submitted', child: Text('Terkirim')),
                DropdownMenuItem(value: 'reviewed', child: Text('Ditinjau')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('Dikerjakan'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('Selesai')),
                DropdownMenuItem(value: 'closed', child: Text('Ditutup')),
                DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
              ],
              onChanged: (val) {
                setState(() => _selectedStatus = val);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterDropdown(
              label: 'Kategori',
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: 'facility', child: Text('Fasilitas')),
                DropdownMenuItem(value: 'security', child: Text('Keamanan')),
                DropdownMenuItem(
                  value: 'cleanliness',
                  child: Text('Kebersihan'),
                ),
                DropdownMenuItem(value: 'noise', child: Text('Kebisingan')),
                DropdownMenuItem(value: 'dispute', child: Text('Perselisihan')),
                DropdownMenuItem(value: 'other', child: Text('Lainnya')),
              ],
              onChanged: (val) {
                setState(() => _selectedCategory = val);
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
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(label, style: AppTextStyles.bodySmall),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onTap;

  const _ComplaintCard({required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        complaint.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      complaint.statusLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _statusColor(complaint.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (complaint.attachmentCount > 0) ...[
                    Icon(Icons.attach_file, size: 16, color: AppColors.grey),
                    const SizedBox(width: 2),
                    Text(
                      '${complaint.attachmentCount}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.referenceNo,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                complaint.title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              if (complaint.description != null &&
                  complaint.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  complaint.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint.categoryLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(complaint.submittedAt ?? complaint.createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.warning;
      case 'reviewed':
        return Colors.blue;
      case 'in_progress':
        return AppColors.primary;
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

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/letter_provider.dart';

class MyLettersPage extends ConsumerStatefulWidget {
  const MyLettersPage({super.key});

  @override
  ConsumerState<MyLettersPage> createState() => _MyLettersPageState();
}

class _MyLettersPageState extends ConsumerState<MyLettersPage> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final lettersAsync = ref.watch(myLettersProvider(_selectedStatus));

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Surat Saya'),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: lettersAsync.when(
              loading: () => _buildSkeleton(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (letters) {
                if (letters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text('Belum ada surat', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        Text(
                          'Ajukan surat baru di menu Surat',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(myLettersProvider(_selectedStatus)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: letters.length,
                    itemBuilder: (context, index) => _LetterListCard(
                      letter: letters[index],
                      onTap: () =>
                          context.push('/letters/${letters[index].id}'),
                    ),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua',
              selected: _selectedStatus == null,
              onTap: () => setState(() => _selectedStatus = null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Menunggu',
              selected: _selectedStatus == 'submitted',
              onTap: () => setState(() => _selectedStatus = 'submitted'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Disetujui',
              selected: _selectedStatus == 'completed',
              onTap: () => setState(() => _selectedStatus = 'completed'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Ditolak',
              selected: _selectedStatus == 'rejected',
              onTap: () => setState(() => _selectedStatus = 'rejected'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          height: 100,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.dark,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LetterListCard extends StatelessWidget {
  final dynamic letter;
  final VoidCallback onTap;

  const _LetterListCard({required this.letter, required this.onTap});

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
                  Expanded(
                    child: Text(
                      letter.letterType?.name ?? 'Surat',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(letter.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      letter.statusLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _statusColor(letter.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.tag, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(letter.referenceNo, style: AppTextStyles.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${letter.formattedDate}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              if (letter.purpose != null && letter.purpose!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  letter.purpose!,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (letter.documents != null && letter.documents!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.attachment, size: 14, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${letter.documents!.length} dokumen',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
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
      case 'approved':
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }
}

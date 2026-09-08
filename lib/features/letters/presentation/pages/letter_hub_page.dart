import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/letter_provider.dart';

class LetterHubPage extends ConsumerWidget {
  const LetterHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(letterTypesProvider);
    final recentAsync = ref.watch(myLettersProvider(null));

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Surat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Buat Surat Baru', Icons.add_circle_outline),
            const SizedBox(height: 12),
            typesAsync.when(
              loading: () => _buildTypeSkeleton(),
              error: (e, _) => _buildErrorCard('Gagal memuat jenis surat'),
              data: (types) {
                if (types.isEmpty) {
                  return _buildEmptyCard('Belum ada jenis surat tersedia');
                }
                return Column(
                  children: types
                      .map(
                        (type) => _LetterTypeCard(
                          name: type.name,
                          description: type.description,
                          fieldCount: type.fieldCountLabel,
                          icon: _typeIcon(type.code),
                          onTap: () =>
                              context.push('/letters/create/${type.id}'),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Surat Saya', Icons.description_outlined),
            const SizedBox(height: 12),
            recentAsync.when(
              loading: () => _buildLetterSkeleton(),
              error: (e, _) => _buildErrorCard('Gagal memuat surat saya'),
              data: (letters) {
                if (letters.isEmpty) {
                  return _buildEmptyCard('Belum ada surat yang diajukan');
                }
                return Column(
                  children: letters
                      .take(3)
                      .map(
                        (letter) => _LetterCard(
                          letter: letter,
                          onTap: () => context.push('/letters/${letter.id}'),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.push('/letters/my'),
                child: const Text('Lihat Semua Surat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headline2.copyWith(fontSize: 18)),
      ],
    );
  }

  Widget _buildTypeSkeleton() {
    return Skeletonizer(
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterSkeleton() {
    return Skeletonizer(
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 88,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(message, style: AppTextStyles.bodySmall)),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(message, style: AppTextStyles.bodySmall)),
    );
  }

  IconData _typeIcon(String code) {
    switch (code) {
      case 'surat_pengantar':
        return Icons.description;
      case 'surat_keterangan_domisili':
        return Icons.home;
      case 'surat_keterangan_usaha':
        return Icons.store;
      default:
        return Icons.article;
    }
  }
}

class _LetterTypeCard extends StatelessWidget {
  final String name;
  final String? description;
  final String fieldCount;
  final IconData icon;
  final VoidCallback onTap;

  const _LetterTypeCard({
    required this.name,
    this.description,
    required this.fieldCount,
    required this.icon,
    required this.onTap,
  });

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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description != null && description!.isNotEmpty)
                      Text(
                        description!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      fieldCount,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final dynamic letter;
  final VoidCallback onTap;

  const _LetterCard({required this.letter, required this.onTap});

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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor(letter.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _statusIcon(letter.status),
                  color: _statusColor(letter.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.letterType?.name ?? 'Surat',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(letter.referenceNo, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.hourglass_empty;
      case 'approved':
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }
}

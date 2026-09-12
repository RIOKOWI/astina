import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../providers/letter_provider.dart';

class LettersPage extends ConsumerStatefulWidget {
  const LettersPage({super.key});

  @override
  ConsumerState<LettersPage> createState() => _LettersPageState();
}

class _LettersPageState extends ConsumerState<LettersPage> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final lettersAsync = ref.watch(
      myLettersProvider((status: _statusFilter, letterTypeId: null, page: 1)),
    );

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Surat Saya'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/letters/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajukan Surat',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  myLettersProvider((
                    status: _statusFilter,
                    letterTypeId: null,
                    page: 1,
                  )),
                );
              },
              child: lettersAsync.when(
                data: (letters) {
                  if (letters.isEmpty) return _buildEmpty();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: letters.length,
                    itemBuilder: (context, index) =>
                        _buildLetterCard(letters[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      friendlyErrorMessage(e),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: _statusFilter == null,
            onSelected: (_) => setState(() => _statusFilter = null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Menunggu'),
            selected: _statusFilter == 'submitted',
            onSelected: (_) => setState(() => _statusFilter = 'submitted'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Disetujui'),
            selected: _statusFilter == 'approved',
            onSelected: (_) => setState(() => _statusFilter = 'approved'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Ditolak'),
            selected: _statusFilter == 'rejected',
            onSelected: (_) => setState(() => _statusFilter = 'rejected'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Selesai'),
            selected: _statusFilter == 'completed',
            onSelected: (_) => setState(() => _statusFilter = 'completed'),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterCard(dynamic letter) {
    return GestureDetector(
      onTap: () => context.push('/letters/${letter.id}'),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor(letter.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.mail_outlined,
                color: _statusColor(letter.status),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    letter.letterType.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    letter.referenceNo,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  if (letter.submittedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(letter.submittedAt!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
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
                _statusLabel(letter.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(letter.status),
                ),
              ),
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
              Icon(Icons.mail_outline, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada surat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ajukan surat baru melalui tombol di bawah',
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.primary;
      case 'approved':
        return Colors.orange;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/datasources/finance_remote_data_source.dart';
import '../../data/models/due_model.dart';
import '../../providers/finance_provider.dart';

class DueDetailPage extends ConsumerStatefulWidget {
  const DueDetailPage({super.key, required this.dueId});

  final int dueId;

  @override
  ConsumerState<DueDetailPage> createState() => _DueDetailPageState();
}

class _DueDetailPageState extends ConsumerState<DueDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBills);
  }

  void _loadBills() {
    ref.read(dueBillsListProvider(widget.dueId).notifier).load();
  }

  Future<void> _refresh() async {
    ref.invalidate(dueDetailProvider(widget.dueId));
    await ref.read(dueBillsListProvider(widget.dueId).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final dueAsync = ref.watch(dueDetailProvider(widget.dueId));
    final billsState = ref.watch(dueBillsListProvider(widget.dueId));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Detail Iuran'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: dueAsync.when(
        data: (due) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _DueHeader(due: due),
              const SizedBox(height: 16),
              _DueInformation(due: due),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tagihan Warga',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${billsState.total} tagihan',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (billsState.error != null)
                _InlineError(message: billsState.error!, onRetry: _loadBills)
              else if (billsState.bills.isEmpty && billsState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (billsState.bills.isEmpty)
                const _EmptyBills()
              else ...[
                for (final bill in billsState.bills) _DueBillTile(bill: bill),
                if (billsState.hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: billsState.isLoading
                          ? null
                          : () => ref
                                .read(
                                  dueBillsListProvider(widget.dueId).notifier,
                                )
                                .loadMore(),
                      icon: billsState.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: const Text('Muat Lagi'),
                    ),
                  ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PageError(
          message: error.toString(),
          onRetry: () => ref.invalidate(dueDetailProvider(widget.dueId)),
        ),
      ),
    );
  }
}

class _DueHeader extends StatelessWidget {
  const _DueHeader({required this.due});

  final DueModel due;

  @override
  Widget build(BuildContext context) {
    final color = due.isActive ? AppColors.success : AppColors.grey;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  due.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(due.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              due.isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DueInformation extends StatelessWidget {
  const _DueInformation({required this.due});

  final DueModel due;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Iuran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Frekuensi', value: due.frequencyLabel),
          _InfoRow(label: 'Mulai', value: due.startDate ?? '-'),
          _InfoRow(label: 'Berakhir', value: due.endDate ?? '-'),
          if (due.description != null && due.description!.isNotEmpty)
            _InfoRow(label: 'Deskripsi', value: due.description!),
        ],
      ),
    );
  }
}

class _DueBillTile extends StatelessWidget {
  const _DueBillTile({required this.bill});

  final DueBillModel bill;

  @override
  Widget build(BuildContext context) {
    final color = switch (bill.status) {
      'paid' || 'approved' => AppColors.success,
      'pending' => Colors.orange,
      'rejected' => AppColors.error,
      _ => AppColors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.resident?.fullName ?? 'Warga #${bill.residentId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Jatuh tempo ${bill.dueDate}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(bill.amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bill.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Belum ada tagihan untuk iuran ini',
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _PageError extends StatelessWidget {
  const _PageError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat detail iuran',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(int amount) {
  final value = amount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $value';
}

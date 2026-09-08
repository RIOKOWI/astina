import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/finance_provider.dart';
import '../../data/models/due_bill_model.dart';

class DueBillsPage extends ConsumerWidget {
  const DueBillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueBillsAsync = ref.watch(dueBillsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Iuran Saya'),
      ),
      body: dueBillsAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dueBills) {
          if (dueBills.isEmpty) {
            return const Center(child: Text('Tidak ada tagihan'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dueBillsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dueBills.length,
              itemBuilder: (context, index) {
                final bill = dueBills[index];
                return _DueBillCard(
                  bill: bill,
                  onPay: () => _showPaymentDialog(context, ref, bill),
                );
              },
            ),
          );
        },
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

  void _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    DueBillModel bill,
  ) {
    String selectedMethod = 'transfer';
    final methods = [
      {'value': 'transfer', 'label': 'Transfer'},
      {'value': 'cash', 'label': 'Tunai'},
      {'value': 'ewallet', 'label': 'E-Wallet'},
      {'value': 'other', 'label': 'Lainnya'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Bayar Tagihan', style: AppTextStyles.headline2),
              const SizedBox(height: 8),
              Text(bill.due?.name ?? 'Iuran', style: AppTextStyles.body),
              const SizedBox(height: 4),
              Text(
                bill.formattedAmount,
                style: AppTextStyles.headline2.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Metode Pembayaran',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: methods.map((m) {
                  final isSelected = selectedMethod == m['value'];
                  return ChoiceChip(
                    label: Text(m['label']!),
                    selected: isSelected,
                    onSelected: (sel) {
                      if (sel) setState(() => selectedMethod = m['value']!);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.grey,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final payment = await ref
                        .read(financeNotifierProvider.notifier)
                        .createPayment(
                          dueBillId: bill.id,
                          amount: bill.amount,
                          method: selectedMethod,
                        );
                    if (payment != null && context.mounted) {
                      context.push('/finance/payments/${payment.id}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Bayar Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueBillCard extends StatelessWidget {
  final DueBillModel bill;
  final VoidCallback onPay;

  const _DueBillCard({required this.bill, required this.onPay});

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
                    color: bill.isPaid
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bill.isPaid ? 'LUNAS' : 'BELUM BAYAR',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: bill.isPaid ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  bill.formattedAmount,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bill.due?.name ?? 'Iuran',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(
                  'Jatuh tempo: ${_formatDate(bill.dueDate)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
            if (!bill.isPaid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onPay,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Bayar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
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
    final month = int.tryParse(parts[1]) ?? 1;
    return '${parts[2]} ${months[month - 1]} ${parts[0]}';
  }
}

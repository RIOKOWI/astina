import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../providers/finance_provider.dart';

class MyDueBillsPage extends ConsumerStatefulWidget {
  const MyDueBillsPage({super.key});

  @override
  ConsumerState<MyDueBillsPage> createState() => _MyDueBillsPageState();
}

class _MyDueBillsPageState extends ConsumerState<MyDueBillsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _load() => ref.read(myDueBillsProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myDueBillsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Tagihan Saya'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: state.error != null
            ? _buildError(state.error!)
            : state.bills.isEmpty && !state.isLoading
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.bills.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.bills.length) {
                    if (state.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    ref.read(myDueBillsProvider.notifier).loadMore();
                    return const SizedBox.shrink();
                  }
                  return _DueBillCard(
                    bill: state.bills[index],
                    onPay: () => _showPaymentDialog(state.bills[index]),
                  );
                },
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
              Icon(Icons.check_circle_outline, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Tidak ada tagihan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              Text(
                'Gagal memuat tagihan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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

  void _showPaymentDialog(dynamic bill) {
    if (!bill.isUnpaid) return;
    context.push('/finance/my/bills/${bill.id}/pay', extra: bill);
  }
}

class _DueBillCard extends StatelessWidget {
  const _DueBillCard({required this.bill, required this.onPay});

  final dynamic bill;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bill.status) {
      'pending' => Colors.orange,
      'approved' => AppColors.success,
      'paid' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.grey,
    };

    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.due?.name ?? 'Iuran',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jatuh tempo: ${bill.dueDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bill.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatCurrency(bill.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (bill.isUnpaid)
                SizedBox(
                  width: 110,
                  child: ElevatedButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Bayar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $str';
  }
}

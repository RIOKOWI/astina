import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/finance_provider.dart';

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final summaryAsync = ref.watch(financeSummaryProvider(null));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Kas RT'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financeSummaryProvider(null));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summaryAsync.when(
                data: (summary) => _buildSummaryCard(summary),
                loading: () => const _SummarySkeleton(),
                error: (e, _) => _buildErrorCard(e.toString()),
              ),
              const SizedBox(height: 24),
              const Text(
                'Navigasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              _buildNavGrid(context, role),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(dynamic summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Kas',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(summary.balance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  Icons.arrow_downward,
                  'Pemasukan',
                  _formatCurrency(summary.totalIncome),
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStat(
                  Icons.arrow_upward,
                  'Pengeluaran',
                  _formatCurrency(summary.totalExpense),
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGrid(BuildContext context, UserRole role) {
    final items = <(IconData, String, String)>[
      (Icons.receipt_long, 'Riwayat Transaksi', '/finance'),
    ];

    if (role == UserRole.rt) {
      items.add((Icons.payments, 'Kelola Iuran', '/finance'));
    }

    if (role == UserRole.warga) {
      items.add((Icons.payments_outlined, 'Tagihan Saya', '/finance'));
    }

    if (role == UserRole.bendahara) {
      items.add((
        Icons.approval,
        'Approval Pembayaran',
        '/finance/payments/pending',
      ));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((e) => _buildNavCard(e.$1, e.$2)).toList(),
    );
  }

  Widget _buildNavCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gagal memuat data',
              style: TextStyle(color: AppColors.error.withValues(alpha: 0.8)),
            ),
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

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 160,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

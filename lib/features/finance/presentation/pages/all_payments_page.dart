import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/payment_model.dart';
import '../../providers/finance_provider.dart';

class AllPaymentsPage extends ConsumerStatefulWidget {
  const AllPaymentsPage({super.key});

  @override
  ConsumerState<AllPaymentsPage> createState() => _AllPaymentsPageState();
}

class _AllPaymentsPageState extends ConsumerState<AllPaymentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    ('all', 'Semua'),
    ('pending', 'Pending'),
    ('approved', 'Disetujui'),
    ('rejected', 'Ditolak'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _tabs[_tabController.index].$1;
    ref.read(allPaymentsProvider.notifier).load(status: status);
  }

  void _load() {
    final status = _tabs[_tabController.index].$1;
    ref.read(allPaymentsProvider.notifier).load(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allPaymentsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: _tabs
              .map(
                (t) => Tab(
                  child: state.statusFilter == t.$1 && state.total > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.$2),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${state.total}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(t.$2),
                ),
              )
              .toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: state.error != null
            ? _buildError(state.error!)
            : state.payments.isEmpty && !state.isLoading
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.payments.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.payments.length) {
                    if (state.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    ref.read(allPaymentsProvider.notifier).loadMore();
                    return const SizedBox.shrink();
                  }
                  return _PaymentCard(
                    payment: state.payments[index],
                    onTap: () async {
                      await context.push(
                        '/finance/payments/${state.payments[index].id}',
                      );
                      if (mounted) _load();
                    },
                  );
                },
              ),
      ),
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
                'Gagal memuat riwayat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  msg,
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

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 64, color: AppColors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.onTap});

  final PaymentModel payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon, color: _statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.resident?.fullName ?? 'Warga',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.dueBill?.due?.name ?? 'Iuran',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _infoChip(
                          Icons.calendar_today,
                          _formatDate(payment.paidAt),
                        ),
                        const SizedBox(width: 8),
                        _infoChip(Icons.payment, _methodLabel(payment.method)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(payment.amount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _statusBadge,
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.grey),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (payment.status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  IconData get _statusIcon {
    switch (payment.status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.payment;
    }
  }

  Widget get _statusBadge {
    final (label, color) = switch (payment.status) {
      'pending' => ('Pending', Colors.orange),
      'approved' => ('Disetujui', AppColors.success),
      'rejected' => ('Ditolak', AppColors.error),
      _ => (payment.status, AppColors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _methodLabel(String method) {
    return switch (method) {
      'transfer' => 'Transfer',
      'cash' => 'Tunai',
      'qris' => 'QRIS',
      'ewallet' => 'E-Wallet',
      _ => method,
    };
  }
}
